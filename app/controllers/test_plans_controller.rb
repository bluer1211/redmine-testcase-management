class TestPlansController < ApplicationController

  include ApplicationsHelper

  before_action :find_project_id
  before_action :find_test_plan, :only => [:show, :edit, :update, :destroy]
  before_action :find_test_plan_id, :only => [:assign_test_case, :unassign_test_case]
  before_action :find_test_cases, :only => [:show_context_menu, :unassign_test_case]
  before_action :authorize_with_issues_permission
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
    unless User.current.allowed_to?(:add_issues, @project, :global => true)
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
      redirect_to project_test_plan_path(:id => @test_plan.id)
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

  private

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
      # csv header fields
      csv << columns.map {|c| c.caption.to_s} + [l(:field_test_cases)]
      # csv lines
      items.each do |item|
        csv << columns.map {|c| csv_content(c, item)} + [item.test_cases.pluck(:id).join(",")]
      end
    end
  end
end
