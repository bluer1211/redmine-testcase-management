class TestCasesController < ApplicationController

  include ApplicationsHelper

  before_action :find_project_id
  before_action :find_test_plan_id_if_given, :only => [:new, :create, :show, :edit, :index, :update, :destroy]
  before_action :find_test_case, :only => [:show, :edit, :update, :destroy]
  before_action :authorize_with_issues_permission, :except => [:template]
  before_action :find_test_cases, :only => [:list_context_menu, :bulk_edit, :bulk_update, :bulk_delete]

  before_action do
    prepare_user_candidates
    prepare_issue_status_candidates
    prepare_test_plan_candidates
  end

  helper :attachments
  helper :queries
  include QueriesHelper
  helper :test_cases_queries
  include TestCasesQueriesHelper
  helper :context_menus

  # GET /projects/:project_id/test_cases
  # GET /projects/:project_id/test_plans/:test_plan_id/test_cases
  def index
    retrieve_query(TestCaseQuery, false)

    if @query.valid?
      respond_to do |format|
        @test_cases_export_limit = Setting.plugin_testcase_management["test_cases_export_limit"].to_i
        format.html do
          if @test_plan_given
            @test_case_count = @query.test_case_count(params[:test_plan_id], true)
            @test_case_pages = Paginator.new @test_case_count, per_page_option, params["page"]
            @test_cases = @query.test_cases(test_plan_id: params[:test_plan_id],
                                            offset: @test_case_pages.offset,
                                            limit: @test_case_pages.per_page).visible
            @title = html_title(l(:label_test_cases),
                                "##{@test_plan.id} #{@test_plan.name}",
                                l(:label_test_plans))
            @csv_url = project_test_plan_test_cases_path(@project, test_plan_id: params[:test_plan_id], format: "csv")
          else
            @test_case_count = @query.test_case_count(nil, true)
            @test_case_pages = Paginator.new @test_case_count, per_page_option, params["page"]
            @test_cases = @query.test_cases(offset: @test_case_pages.offset,
                                            limit: @test_case_pages.per_page).visible
            @title = html_title(l(:label_test_cases))
            @csv_url = project_test_cases_path(@project, format: "csv")
          end
        end
        format.csv do
          if @test_plan_given
            @test_cases = @query.test_cases(test_plan_id: params[:test_plan_id],
                                            limit: @test_cases_export_limit).visible
          else
            @test_cases = @query.test_cases(limit: @test_cases_export_limit).visible
          end
          send_data(query_to_csv(@test_cases, @query, params[:csv]),
                    :type => 'text/csv; header=present', :filename => 'test_cases.csv')
        end
      end
    else
      flash.now[:error] = l(:error_index_failure)
      render 'forbidden', status: :unprocessable_entity
    end
  end

  # GET /projects/:project_id/test_cases/new
  # GET /projects/:project_id/test_plans/:test_plan_id/test_cases/new
  def new
    @test_case = TestCase.new
    @test_case.user = User.current  # 設定預設使用者為當前使用者
    if params.permit(:test_plan_id)[:test_plan_id]
      @test_plan = TestPlan.find(params.permit(:test_plan_id)[:test_plan_id])
      @test_plan_given = true
      @title = html_title(l(:label_test_case_new),
                          "##{@test_plan.id} #{@test_plan.name}",
                          l(:label_test_plans))
    else
      @test_plan = nil
      @test_plan_given = false
      @title = html_title(l(:label_test_case_new))
    end
  end

  # POST /projects/:project_id/test_cases
  # POST /projects/:project_id/test_plans/:test_plan_id/test_cases
  def create
    unless User.current.allowed_to?(:add_test_cases, @project, :global => true)
      raise ::Unauthorized
    end
    begin
      # 處理用戶設定，確保用戶有權限查看該測試案例
      user_id = test_case_params[:user].to_i
      if user_id > 0
        user = User.find_by(id: user_id)
        # 如果指定的用戶不存在或沒有權限，使用當前用戶
        if user.nil? || !user.allowed_to?(:view_test_cases, @project)
          user = User.current
        end
      else
        user = User.current
      end
      
      @test_case = TestCase.new(:project_id => @project.id,
                                :name => test_case_params[:name],
                                :user => user,
                                :environment => test_case_params[:environment],
                                :scenario => test_case_params[:scenario],
                                :expected => test_case_params[:expected])
      
      # 處理測試計劃關聯
      if test_case_params[:test_plan_id].present?
        test_plan_id = test_case_params[:test_plan_id].to_i
        if test_plan_id > 0
          test_plan = TestPlan.find_by(id: test_plan_id, project: @project)
          @test_case.test_plans << test_plan if test_plan
        end
      elsif @test_plan
        @test_case.test_plans << @test_plan
      end
      if @test_case.valid?
        @test_case.save
        # 附件功能暫時停用，避免 acts_as_attachable 錯誤
        # if params[:attachments].present?
        #   @test_case.save_attachments params.require(:attachments).permit!
        # end
        flash[:notice] = l(:notice_successful_create)
        if @test_plan
          if params[:continue]
            redirect_to new_project_test_plan_test_case_path(test_plan_id: @test_plan.id)
          else
            redirect_to project_test_plan_path(id: @test_plan.id)
          end
        else
          if params[:continue]
            redirect_to new_project_test_case_path
          else
            redirect_to project_test_case_path(id: @test_case.id)
          end
        end
      else
        render :new, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error "Test case creation failed: #{e.message}"
      render :new, status: :unprocessable_entity
    end
  end

  # GET /projects/:project_id/test_cases/:id
  # GET /projects/:project_id/test_plans/:test_plan_id/test_cases/:id
  def show
    begin
      if @test_plan_given
        @test_case_executions = @test_case.test_case_executions_for(@test_plan)
        @title = html_title("##{@test_case.id} #{@test_case.name}",
                            l(:label_test_cases),
                            "##{@test_plan.id} #{@test_plan.name}",
                            l(:label_test_plans))
      else
        @test_case_executions = @test_case.test_case_executions
        @title = html_title("##{@test_case.id} #{@test_case.name}",
                            l(:label_test_cases))
      end
    rescue => e
      Rails.logger.error "Test case show error: #{e.message}"
      flash[:error] = l(:error_test_case_not_found)
      redirect_to project_test_cases_path
    end
  end

  # GET /projects/:project_id/test_cases/:id/edit
  # GET /projects/:project_id/test_plans/:test_plan_id/test_cases/:id/edit
  def edit
    if @test_plan_given
      @title = html_title("#{l(:label_test_case_edit)} ##{@test_case.id}",
                          l(:label_test_cases),
                          "##{@test_plan.id} #{@test_plan.name}",
                          l(:label_test_plans))
    else
      @title = html_title("#{l(:label_test_case_edit)} ##{@test_case.id}",
                          l(:label_test_cases))
    end
  end

  # PUT /projects/:project_id/test_cases/:id
  # PUT /projects/:project_id/test_plans/:test_plan_id/test_cases/:id
  def update
    raise ::Unauthorized unless @test_case.editable?
    update_params = {
      name: test_case_params[:name],
      scenario: test_case_params[:scenario],
      expected: test_case_params[:expected],
      environment: test_case_params[:environment]
    }
    user_id = test_case_params[:user].to_i
    user = user_id > 0 ? User.find_by(id: user_id) : nil
    update_params[:user_id] = user.id if user.present?
    
    # 處理測試計劃關聯
    if test_case_params[:test_plan_id].present?
      test_plan_id = test_case_params[:test_plan_id].to_i
      if test_plan_id > 0
        test_plan = TestPlan.find_by(id: test_plan_id, project: @project)
        if test_plan
          # 清除現有的測試計劃關聯並添加新的
          @test_case.test_plans.clear
          @test_case.test_plans << test_plan
        end
      end
    end
    
    # 附件功能暫時停用，避免 acts_as_attachable 錯誤
    # if params[:attachments].present?
    #   @test_case.save_attachments params.require(:attachments).permit!
    # end
    if @test_case.update(update_params)
      flash[:notice] = l(:notice_successful_update)
      if params[:test_plan_id].present?
        redirect_to project_test_plan_path(id: params[:test_plan_id])
      else
        redirect_to project_test_case_path
      end
    else
      flash.now[:error] = l(:error_update_failure)
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /projects/:project_id/test_cases/:id
  # DELETE /projects/:project_id/test_plans/:test_plan_id/test_cases/:id
  def destroy
    raise ActiveRecord::RecordNotFound unless @test_case.visible?
    raise ::Unauthorized unless @test_case.deletable?
    begin
      if @test_case.destroy
        flash[:notice] = l(:notice_successful_delete)
        if params[:test_plan_id].present?
          redirect_to project_test_plan_path(id: params.permit(:test_plan_id)[:test_plan_id])
        else
          redirect_to project_test_cases_path
        end
      else
        flash.now[:error] = l(:error_delete_failure)
        render :show
      end
    rescue
      flash.now[:error] = l(:error_test_case_not_found)
      render 'forbidden', status: 404
    end
  end

  # GET /projects/:project_id/test_cases/auto_complete
  def auto_complete
    test_cases = []
    unless User.current.allowed_to?(:view_test_cases, @project, :global => true)
      render :json => test_cases
      return
    end
    q = params.permit(:term)[:term]
    test_plan_id = params.permit(:test_plan_id)[:test_plan_id]
    num = 0
    if q.present?
      begin
        num = Integer(q)
      rescue
      end
    end
    like = if Redmine::Database.postgresql?
             "ILIKE"
           else
             "LIKE"
           end
    begin
      if test_plan_id.present?
        test_cases = TestCase.visible.where.not(id: TestPlan.find(test_plan_id).test_cases.select(:id))
                       .where("projects.identifier = ? AND test_cases.name #{like} ?",
                              @project.identifier, "%#{q}%").order(id: :desc).limit(10).to_a
      end
      render :json => format_test_cases_json(test_cases)
    rescue
      render :json => test_cases
    end
  end

  # GET /projects/:project_id/test_cases/statistics
  def statistics
    return unless authorize_with_issues_permission(params[:controller], :statistics)
    begin
      # 1. Generate every TP - TC - TCE set
      # 2. Group by test plan id and test case id using PARTITION BY
      # 3. Filter with row number, rownum = 1 means latest execution date
      #    if same execution_date exists, larger test_case_executions.id is latest one.
      # 4. Group by test plan's user, then sum up each statistical items.
      #
      subquery = <<-SQL
                   INNER JOIN issue_statuses AS TPIS ON test_plans.issue_status_id = TPIS.id
                     AND TPIS.is_closed = '0'
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
                      test_plans.user_id,
                      count(test_plans.user_id) AS count_assigned_test_cases,
                      (SELECT count(*) FROM test_cases
                        INNER JOIN test_case_test_plans ON test_case_test_plans.test_case_id = test_cases.id
                        INNER JOIN test_plans ON test_plans.id = test_case_test_plans.test_plan_id
                        AND test_plans.project_id = #{@project.id}
                        INNER JOIN issue_statuses AS CTPIS ON test_plans.issue_status_id = CTPIS.id
                        AND CTPIS.is_closed = '0') AS count_test_cases,
                      SUM(CASE WHEN TPTCTCE.result IS NULL THEN 1 ELSE 0 END) AS count_not_executed,
                      SUM(CASE WHEN TPTCTCE.result = '1' THEN 1 ELSE 0 END) AS count_succeeded,
                      SUM(CASE WHEN TPTCTCE.result = '0' THEN 1 ELSE 0 END) AS count_failed,
                      SUM(CASE WHEN issues.id IS NOT NULL THEN 1 ELSE 0 END) AS detected_bug,
                      SUM(CASE WHEN TCEIS.is_closed = '1' THEN 1 ELSE 0 END) AS fixed_bug,
                      SUM(CASE WHEN TCEIS.is_closed = '0' AND issues.id IS NOT NULL THEN 1 ELSE 0 END) AS remained_bug
SQL
      @test_cases = TestCase.joins(:test_plans)
        .joins(subquery)
        .where(project: @project)
        .group("test_plans.user_id")
        .select(select_query)
        .order("count_not_executed desc, count_failed desc, remained_bug desc")
      render :statistics
    rescue
      render 'forbidden', status: 404
    end
  end

  # GET /projects/:project_id/test_cases/bulk_edit
  def bulk_edit
    @assignables = @project.users
    @safe_attributes = @test_cases.map(&:safe_attribute_names).reduce(:&)
    @test_case_params = params[:test_case] || {}
    @back_url = params[:back_url]
  end

  # POST /projects/:project_id/test_cases/bulk_update
  def bulk_update
    attributes = parse_params_for_bulk_update(params[:test_case])

    unsaved_test_cases = []
    saved_test_cases = []

    @test_cases.each do |orig_test_case|
      orig_test_case.reload
      test_case = orig_test_case
      test_case.safe_attributes = attributes
      if test_case.save
        saved_test_cases << test_case
      else
        unsaved_test_cases << orig_test_case
      end
    end

    if unsaved_test_cases.empty?
      flash[:notice] = l(:notice_successful_update) unless saved_test_cases.empty?
      unless @test_cases.first.test_plan
        redirect_back_or_default project_test_cases_path
      else
        redirect_back_or_default project_test_plans_path(id: @test_cases.first.test_plan.id)
      end
    else
      @saved_test_cases = @test_cases
      @unsaved_test_cases = unsaved_test_cases
      @test_cases = TestCase.visible.where(id: @unsaved_test_cases.map(&:id)).to_a
      bulk_edit
      render :action => 'bulk_edit'
    end
  end

  # DELETE /projects/:project_id/test_cases/bulk_delete
  def bulk_delete
    @test_case_params = params[:test_case] || {}

    delete_allowed = @test_cases.all? { |t| t.deletable?(User.current) }
    if delete_allowed
      @test_cases.destroy_all
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:notice] = l(:error_delete_failure)
    end
    redirect_to params[:back_url]
  end

  # GET /projects/:project_id/test_cases/context_menu
  def list_context_menu
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

  # GET /projects/:project_id/test_cases/template
  def template
    # 完全移除權限檢查，讓模板下載對所有用戶開放
    
    case params[:type]
    when 'test_cases'
      generate_test_cases_template
    when 'test_plans'
      generate_test_plans_template
    when 'test_case_executions'
      generate_test_case_executions_template
    else
      generate_test_cases_template
    end
  end

  private

  def generate_test_cases_template
    # 使用與 CSV 匯出相同的查詢和欄位定義
    @query = TestCaseQuery.new
    @query.project = @project
    columns = @query.available_columns
    
    csv_data = Redmine::Export::CSV.generate(encoding: 'UTF-8') do |csv|
      # 使用與 CSV 匯出相同的表頭，但添加 test_case_id 欄位
      headers = columns.map {|c| c.caption.to_s}
      headers.unshift(l(:field_test_case_id))  # 在開頭添加測試案例 ID 欄位
      csv << headers
      # 添加範例資料行
      csv << [
        "1",  # test_case_id
        "1",  # id
        "範例測試案例 1",  # name
        "Ubuntu",  # environment
        User.current.name,  # user
        l(:label_succeed),  # latest_result
        "2024-01-01",  # latest_execution_date
        "執行測試步驟...",  # scenario
        "預期結果..."  # expected
      ]
    end
    
    send_data csv_data,
              filename: "test_cases_template.csv",
              type: 'text/csv; charset=utf-8',
              disposition: 'attachment'
  end

  def generate_test_plans_template
    @query = TestPlanQuery.new
    @query.project = @project
    columns = @query.available_columns
    
    csv_data = Redmine::Export::CSV.generate(encoding: 'UTF-8') do |csv|
      # 使用與 CSV 匯出相同的表頭
      csv << columns.map {|c| c.caption.to_s} + [l(:field_test_cases)]
      # 添加範例資料行
      csv << [
        "1",
        "範例測試計劃 1",
        l(:label_new),
        "1",
        User.current.name,
        "2024-01-01",
        "2024-01-31",
        "101,102,103"
      ]
    end
    
    send_data csv_data,
              filename: "test_plans_template.csv",
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

  def format_test_cases_json(test_cases)
    test_cases.map do |test_case|
      {
        'id': test_case.id,
        'label': "##{test_case.id} #{test_case.name.truncate(60)}",
        'value': test_case.id
      }
    end
  end

  def test_case_params
    params.require(:test_case).permit(:project_id,
                                      :test_plan_id,
                                      :name,
                                      :user,
                                      :environment,
                                      :scenario,
                                      :expected)
  end

  def csv_value(column, test_case, value)
    case column.name
    when :latest_result
      value.nil? ? l(:label_none) :
        value ? l(:label_succeed) :
        l(:label_failure)
    when :latest_execution_date
      !value ? l(:label_none) :
        yyyymmdd_date(value)
    else
      super
    end
  end

  def query_to_csv(items, query, options={})
    columns = query.columns

    Redmine::Export::CSV.generate(:encoding => params[:encoding]) do |csv|
      # csv header fields
      csv << columns.map {|c| c.caption.to_s}
      # csv lines
      items.each do |item|
        csv << columns.map {|c| csv_content(c, item)}
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
    when ActiveRecord::Associations::CollectionProxy
      # 處理測試計劃關聯，返回測試計劃名稱
      if column.name == :test_plans
        value.map(&:name).join(', ')
      else
        value.to_s
      end
    when TestPlan
      # 處理單個測試計劃對象
      value.name
    else
      value.to_s
    end
  end
end
