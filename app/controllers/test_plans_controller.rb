class TestPlansController < ApplicationController

  include ApplicationsHelper

  before_action :find_project_id
  before_action :find_test_plan, :only => [:show, :edit, :update, :destroy]
  before_action :find_test_plan_id, :only => [:assign_test_case, :unassign_test_case]
  before_action :find_test_cases, :only => [:show_context_menu, :unassign_test_case]
  before_action :authorize_with_issues_permission, :except => [:template]
  before_action :find_test_plans, :only => [:list_context_menu, :bulk_edit, :bulk_update, :bulk_delete]

  before_action do
    prepare_issue_status_candidates
    prepare_user_candidates
  end

  helper :queries
  include QueriesHelper
  helper :test_plans_queries
  include TestPlansQueriesHelper
  helper :context_menus

  # GET /projects/:project_id/test_plans
  def index
    retrieve_query(TestPlanQuery, false)

    if @query.valid?
      respond_to do |format|
        @test_plans_export_limit = Setting.plugin_testcase_management["test_plans_export_limit"].to_i
        format.html do
          @test_plan_count = @query.test_plan_count
          @test_plan_pages = Paginator.new @test_plan_count, per_page_option, params["page"]
          test_plans_params = {offset: @test_plan_pages.offset,
                               limit: @test_plan_pages.per_page}
          if params[:test_case_id].present?
            test_plans_params[:test_case_id] = params[:test_case_id]
          end
          @test_plans = @query.test_plans(test_plans_params).visible
          @title = html_title(l(:label_test_plans))
          @csv_url = project_test_plans_path(@project, format: "csv")
        end
        format.csv do
          test_plans_params = {limit: @test_plans_export_limit}
          if params[:test_case_id].present?
            test_plans_params[:test_case_id] = params[:test_case_id]
          end
          @test_plans = @query.test_plans(test_plans_params).visible
          send_data(query_to_csv(@test_plans, @query, params[:csv]),
                    :type => 'text/csv; header=present', :filename => 'test_plans.csv')
        end
      end
    else
      flash.now[:error] = l(:error_index_failure)
      render 'forbidden', status: :unprocessable_entity
    end
  end

  # GET /projects/:project_id/test_plans/:id
  def show
    @test_case_test_plan = TestCaseTestPlan.new

    @title = html_title("##{@test_plan.id} #{@test_plan.name}", l(:label_test_plans))

    retrieve_query(TestCaseQuery, false)
    if @query.valid?
      # 在測試計劃詳細頁面，設定不包含測試計劃欄位的欄位列表
      @query.column_names = [:id, :name, :scenario, :expected, :latest_result, :latest_execution_date, :environment, :user]
      
      @test_case_count = @query.test_case_count(params[:id], true)
      @test_case_pages = Paginator.new @test_case_count, per_page_option, params["page"]
      @test_cases = @query.test_cases(test_plan_id: params[:id],
                                      offset: @test_case_pages.offset,
                                      limit: @test_case_pages.per_page).visible
    end
  end

  # GET /projects/:project_id/test_plans/:id/edit
  def edit
    @title = html_title("#{l(:label_test_plan_edit)} ##{@test_plan.id}")
  end

  # PUT /projects/:project_id/test_plans/:id
  def update
    raise ::Unauthorized unless @test_plan.editable?
    update_params = {}
    update_params[:name] = test_plan_params[:name]
    update_params[:begin_date] = test_plan_params[:begin_date]
    update_params[:end_date] = test_plan_params[:end_date]
    update_params[:estimated_bug] = test_plan_params[:estimated_bug]
    if test_plan_params[:user].present?
      user = User.find(test_plan_params[:user])
      update_params[:user_id] = user.id
    end
    if test_plan_params[:issue_status].present?
      issue_status = IssueStatus.find(test_plan_params[:issue_status])
      update_params[:issue_status_id] = issue_status.id
    end
    if @test_plan.update(update_params)
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_test_plan_path
    else
      flash.now[:error] = l(:error_update_failure)
      render :edit
    end
  end

  # GET /projects/:project_id/test_plans/new
  def new
    @test_plan = TestPlan.new
    @title = html_title(l(:label_test_plan_new))
  end

  # POST /projects/:project_id/test_plans
  def create
    unless User.current.allowed_to?(:add_test_plans, @project, :global => true)
      raise ::Unauthorized
    end
    @test_plan = TestPlan.new(:name => test_plan_params[:name],
                              :begin_date => test_plan_params[:begin_date],
                              :end_date => test_plan_params[:end_date],
                              :user => User.find(test_plan_params[:user].to_i),
                              :estimated_bug => test_plan_params[:estimated_bug],
                              :issue_status => IssueStatus.find(test_plan_params[:issue_status].to_i),
                              :project_id => @project.id)
    if @test_plan.valid?
      @test_plan.save
      flash[:notice] = l(:notice_successful_create)
      if params[:continue]
        redirect_to new_project_test_plan_path(@project)
      else
        redirect_to project_test_plan_path(:id => @test_plan.id)
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  # DELETE /projects/:project_id/test_plans/:id
  def destroy
    raise ActiveRecord::RecordNotFound unless @test_plan.visible?
    raise ::Unauthorized unless @test_plan.deletable?
    begin
      if @test_plan.destroy
        flash[:notice] = l(:notice_successful_delete)
        redirect_to project_test_plans_path
      else
        flash.now[:error] = l(:error_delete_failure)
        render :show
      end
    rescue
      flash.now[:error] = l(:error_test_plan_not_found)
      render 'forbidden', status: 404
    end
  end

  # POST /projects/:project_id/test_plans/:test_plan_id/assign_test_case
  def assign_test_case
    begin
      @test_case = TestCase.find(params.require(:test_case_test_plan).permit(:test_case_id)[:test_case_id])
      raise ActiveRecord::RecordNotFound unless @test_case.visible?
      raise ActiveRecord::RecordNotFound unless @test_plan.visible?
      @test_case_test_plan = TestCaseTestPlan.where(test_plan: @test_plan,
                                                    test_case: @test_case).first
      unless @test_case_test_plan
        @test_case_test_plan = TestCaseTestPlan.new(test_plan: @test_plan,
                                                    test_case: @test_case)
        if @test_case_test_plan.save
          flash[:notice] = l(:notice_successful_update)
        end
      end
      redirect_to project_test_plan_path(id: @test_plan.id)
    rescue ActiveRecord::RecordNotFound
      flash[:error] = l(:error_test_case_not_found) unless @test_case
      redirect_to project_test_plan_path(id: @test_plan.id)
    rescue
      render 'forbidden', status: 404
    end
  end

  # DELETE /projects/:project_id/test_plans/:test_plan_id/assign_test_case/:id
  # DELETE /projects/:project_id/test_plans/:test_plan_id/assign_test_case/?ids[]=ID1&ids[]=ID2 ...
  def unassign_test_case
    begin
      raise ActiveRecord::RecordNotFound unless @test_cases.all?(&:visible?)
      raise ActiveRecord::RecordNotFound unless @test_plan.visible?
      @test_cases.each do |test_case|
        @test_case_test_plan = TestCaseTestPlan.where(test_plan: @test_plan,
                                                      test_case: test_case).first
        if @test_case_test_plan
          @test_case_test_plan.destroy
          # FIXME: unassign without full rendering, use remote XHR
          flash[:notice] = l(:notice_successful_delete)
        end
      end
      redirect_to project_test_plan_path(id: @test_plan.id)
    rescue
      render 'forbidden', status: 404
    end
  end

  # GET /projects/:project_id/test_plans/statistics
  def statistics
    begin
      #
      # 1. Generate every TP - TC - TCE set
      # 2. Group by test plan id and test case id using PARTITION BY
      # 3. Filter with row number, rownum = 1 means latest execution date
      #    if same execution_date exists, larger test_case_executions.id is latest one.
      #
      join_query = <<-SQL
                      LEFT JOIN (
                        SELECT * FROM (
                          SELECT *, row_number() OVER (
                            PARTITION BY test_plan_id, test_case_id
                            ORDER BY execution_date desc, id desc
                          ) AS rownum
                          FROM test_case_executions
                        ) AS TCE
                        WHERE TCE.rownum = 1
                        ) AS TPTCTCE
                          ON TPTCTCE.test_plan_id = test_case_test_plans.test_plan_id 
                          AND TPTCTCE.test_case_id  = test_case_test_plans.test_case_id 
                      LEFT JOIN issues ON TPTCTCE.issue_id = issues.id
                      LEFT JOIN issue_statuses AS TCEIS ON TCEIS.id = issues.status_id
SQL
      select_query = <<-SQL
                      test_plans.id, test_plans.name, test_plans.user_id, test_plans.estimated_bug,
                      SUM(CASE WHEN TPTCTCE.result IS NULL THEN 1 ELSE 0 END) AS count_not_executed,
                      SUM(CASE WHEN TPTCTCE.result = '1' THEN 1 ELSE 0 END) AS count_succeeded,
                      SUM(CASE WHEN TPTCTCE.result = '0' THEN 1 ELSE 0 END) AS count_failed,
                      SUM(CASE WHEN issues.id IS NOT NULL THEN 1 ELSE 0 END) AS detected_bug,
                      SUM(CASE WHEN TCEIS.is_closed = '1' THEN 1 ELSE 0 END) AS fixed_bug,
                      SUM(CASE WHEN TCEIS.is_closed = '0' AND issues.id IS NOT NULL THEN 1 ELSE 0 END) AS remained_bug
SQL
      @test_plans = TestPlan.joins(:test_cases)
                      .joins(join_query)
                      .where(project: @project)
                      .group(:id)
                      .select(select_query)
                      .order(id: :desc)
      
      # 計算合計數據 - 使用安全的方法
      begin
        total_test_cases = 0
        total_not_executed = 0
        total_succeeded = 0
        total_failed = 0
        total_estimated_bug = 0
        total_detected_bug = 0
        total_remained_bug = 0
        total_fixed_bug = 0
        
        @test_plans.each do |tp|
          # 安全地獲取測試案例數量
          test_cases_count = tp.respond_to?(:test_cases) ? tp.test_cases.size : 0
          total_test_cases += test_cases_count
          
          # 安全地獲取統計數據
          total_not_executed += tp.respond_to?(:count_not_executed) ? (tp.count_not_executed || 0) : 0
          total_succeeded += tp.respond_to?(:count_succeeded) ? (tp.count_succeeded || 0) : 0
          total_failed += tp.respond_to?(:count_failed) ? (tp.count_failed || 0) : 0
          total_estimated_bug += tp.respond_to?(:estimated_bug) ? (tp.estimated_bug || 0) : 0
          total_detected_bug += tp.respond_to?(:detected_bug) ? (tp.detected_bug || 0) : 0
          total_remained_bug += tp.respond_to?(:remained_bug) ? (tp.remained_bug || 0) : 0
          total_fixed_bug += tp.respond_to?(:fixed_bug) ? (tp.fixed_bug || 0) : 0
        end
        
        # 計算百分比
        total_succeeded_rate = total_test_cases > 0 ? ((total_succeeded.to_f / total_test_cases) * 100).round : '-'
        total_progress_rate = total_test_cases > 0 ? (((total_succeeded + total_failed).to_f / total_test_cases) * 100).round : '-'
        total_pass_rate = (total_succeeded + total_failed) > 0 ? ((total_succeeded.to_f / (total_succeeded + total_failed)) * 100).round : '-'
        total_fixed_rate = total_detected_bug > 0 ? ((total_fixed_bug.to_f / total_detected_bug) * 100).round : '-'
        
        @totals = {
          test_cases: total_test_cases,
          not_executed: total_not_executed,
          succeeded: total_succeeded,
          failed: total_failed,
          succeeded_rate: total_succeeded_rate,
          progress_rate: total_progress_rate,
          pass_rate: total_pass_rate,
          estimated_bug: total_estimated_bug,
          detected_bug: total_detected_bug,
          remained_bug: total_remained_bug,
          fixed_rate: total_fixed_rate
        }
      rescue => e
        # 如果計算合計時出錯，設置為空值
        @totals = nil
      end
      
      @title = html_title(l(:label_test_plan_statistics))
      render :statistics
    rescue
      render 'forbidden', status: 404
    end
  end

  # GET /projects/:project_id/test_plans/:id/context_menu
  def show_context_menu
    if @test_cases.size == 1
      @test_case = @test_cases.first
    end
    @test_case_ids = @test_cases.map(&:id).sort

    edit_allowed = @test_cases.all? {|t| t.editable?(User.current)}
    @can = {:edit => edit_allowed, :delete => edit_allowed}
    @back = back_url

    @safe_attributes = @test_cases.map(&:safe_attribute_names).reduce(:&)
    @assignables = @project.users
    render :layout => false
  end

  # GET /projects/:project_id/test_plans/context_menu
  def list_context_menu
    if @test_plans.size == 1
      @test_plan = @test_plans.first
    end
    @test_plan_ids = @test_plans.map(&:id).sort

    edit_allowed = @test_plans.all? {|t| t.editable?(User.current)}
    @can = {:edit => edit_allowed, :delete => edit_allowed}
    @back = back_url

    @safe_attributes = @test_plans.map(&:safe_attribute_names).reduce(:&)
    @assignables = @project.users
    render :layout => false
  end

  def bulk_edit
    @assignables = @project.users
    @safe_attributes = @test_plans.map(&:safe_attribute_names).reduce(:&)
    @test_plan_params = params[:test_plan] || {}
    @back_url = params[:back_url]
  end

  def bulk_update
    attributes = parse_params_for_bulk_update(params[:test_plan])

    unsaved_test_plans = []
    saved_test_plans = []

    @test_plans.each do |orig_test_plan|
      orig_test_plan.reload
      test_plan = orig_test_plan
      test_plan.safe_attributes = attributes
      if test_plan.save
        saved_test_plans << test_plan
      else
        unsaved_test_plans << orig_test_plan
      end
    end

    if unsaved_test_plans.empty?
      flash[:notice] = l(:notice_successful_update) unless saved_test_plans.empty?
      redirect_to params[:back_url]
    else
      @saved_test_plans = @test_plans
      @unsaved_test_plans = unsaved_test_plans
      @test_plans = TestPlan.visible.where(id: @unsaved_test_plans.map(&:id)).to_a
      bulk_edit
      render :action => 'bulk_edit'
    end
  end

  # DELETE /projects/:project_id/test_plans/bulk_delete
  def bulk_delete
    @test_plan_params = params[:test_plan] || {}

    delete_allowed = @test_plans.all? { |t| t.editable?(User.current) }
    if delete_allowed
      @test_plans.destroy_all
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:notice] = l(:error_delete_failure)
    end
    redirect_to params[:back_url]
  end

  # GET /projects/:project_id/test_plans/template
  def template
    # 完全移除權限檢查，讓模板下載對所有用戶開放
    
    case params[:type]
    when 'test_plans'
      generate_test_plans_template
    when 'test_cases'
      generate_test_cases_template
    when 'test_case_executions'
      generate_test_case_executions_template
    else
      generate_test_plans_template
    end
  end

  private

  def generate_test_plans_template
    @query = TestPlanQuery.new
    @query.project = @project
    columns = @query.available_columns
    
    csv_data = Redmine::Export::CSV.generate(encoding: 'UTF-8') do |csv|
      # 使用與 CSV 匯出相同的表頭，但添加 test_plan_id 欄位
      headers = columns.map {|c| c.caption.to_s} + [l(:field_test_cases)]
      headers.unshift(l(:field_test_plan_id))  # 在開頭添加測試計劃 ID 欄位
      csv << headers
      # 添加範例資料行
      csv << [
        "1",  # test_plan_id
        "1",  # id
        "範例測試計劃 1",  # name
        l(:label_new),  # issue_status
        "1",  # estimated_bug
        User.current.name,  # user
        "2024-01-01",  # begin_date
        "2024-01-31",  # end_date
        "101,102,103"  # test_cases
      ]
    end
    
    send_data csv_data,
              filename: "test_plans_template.csv",
              type: 'text/csv; charset=utf-8',
              disposition: 'attachment'
  end

  def generate_test_cases_template
    @query = TestCaseQuery.new
    @query.project = @project
    columns = @query.available_columns
    
    csv_data = Redmine::Export::CSV.generate(encoding: 'UTF-8') do |csv|
      # 使用與 CSV 匯出相同的表頭
      csv << columns.map {|c| c.caption.to_s}
      # 添加範例資料行
      csv << [
        "1",
        "範例測試案例 1",
        "Ubuntu",
        User.current.name,
        l(:label_succeed),
        "2024-01-01",
        "執行測試步驟...",
        "預期結果..."
      ]
    end
    
    send_data csv_data,
              filename: "test_cases_template.csv",
              type: 'text/csv; charset=utf-8',
              disposition: 'attachment'
  end

  def generate_test_case_executions_template
    @query = TestCaseExecutionQuery.new
    @query.project = @project
    columns = @query.available_columns
    
    csv_data = Redmine::Export::CSV.generate(encoding: 'UTF-8') do |csv|
      # 使用與 CSV 匯出相同的表頭
      csv << columns.map {|c| c.caption.to_s}
      # 添加範例資料行
      csv << [
        "1",
        "範例測試案例 1",
        "範例測試計劃 1",
        l(:label_succeed),
        User.current.name,
        "1",
        "執行備註",
        "測試步驟...",
        "預期結果...",
        "2024-01-01 10:00:00"
      ]
    end
    
    send_data csv_data,
              filename: "test_case_executions_template.csv",
              type: 'text/csv; charset=utf-8',
              disposition: 'attachment'
  end

  def test_plan_params
    params.require(:test_plan).permit(:project_id,
                                      :name,
                                      :user,
                                      :begin_date,
                                      :end_date,
                                      :estimated_bug,
                                      :issue_status)
  end

  def query_to_csv(items, query, options={})
    columns = query.columns

    Redmine::Export::CSV.generate(:encoding => params[:encoding]) do |csv|
      # csv header fields - 如果已經包含 test_case_ids 欄位，就不需要額外添加 test_cases 欄位
      if columns.any? {|c| c.name == :test_case_ids}
        csv << columns.map {|c| c.caption.to_s}
      else
        csv << columns.map {|c| c.caption.to_s} + [l(:field_test_cases)]
      end
      # csv lines
      items.each do |item|
        if columns.any? {|c| c.name == :test_case_ids}
          csv << columns.map {|c| csv_content(c, item)}
        else
          csv << columns.map {|c| csv_content(c, item)} + [item.test_cases.map(&:id).join(",")]
        end
      end
    end
  end

  def csv_content(column, item)
    value = item.send(column.name) if item.respond_to?(column.name)
    case value
    when Date
      format_date(value)
    when Time
      format_time(value)
    when Array
      value.join(', ')
    else
      value.to_s
    end
  end
end
