class TestPlansController < ApplicationController

  include ApplicationsHelper

  before_action :find_project_id
  before_action :find_test_plan, :only => [:show, :edit, :update, :destroy]
  before_action :find_test_plan_id, :only => [:assign_test_case, :unassign_test_case]
  before_action :find_test_case_id, :only => [:unassign_test_case]
  before_action :authorize_with_issues_permission, :except => [:index, :new, :create, :assign_test_case, :unassign_test_case, :statistics]

  before_action do
    prepare_issue_status_candidates
    prepare_user_candidates
  end

  helper :queries
  include QueriesHelper
  helper :test_plans_queries
  include TestPlansQueriesHelper

  # GET /projects/:project_id/test_plans
  def index
    retrieve_query(TestPlanQuery, false)

    if @query.valid?
      respond_to do |format|
        format.html do
          @test_plan_count = @query.test_plan_count
          @test_plan_pages = Paginator.new @test_plan_count, per_page_option, params['page']
          test_plans_params = {offset: @test_plan_pages.offset,
                                         limit: @test_plan_pages.per_page}
          if params[:test_case_id].present?
            test_plans_params[:test_case_id] = params[:test_case_id]
          end
          @test_plans = @query.test_plans(test_plans_params).visible
        end
        format.csv do
          max_export = Setting.plugin_testcase_management["test_plans_export_limit"].to_i
          test_plans_params = {limit: max_export}
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
  end

  # GET /projects/:project_id/test_plans/:id/edit
  def edit
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
    return unless authorize_with_issues_permission(params[:controller], :create)
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

  # DELETE /projects/:project_id/test_plans/:test_plan_id/assign_test_case/:test_case_id
  def unassign_test_case
    return unless authorize_with_issues_permission(params[:controller], :destroy)
    begin
      raise ActiveRecord::RecordNotFound unless @test_case.visible?
      raise ActiveRecord::RecordNotFound unless @test_plan.visible?
      @test_case_test_plan = TestCaseTestPlan.where(test_plan: @test_plan,
                                                    test_case: @test_case).first
      if @test_case_test_plan
        @test_case_test_plan.destroy
        # FIXME: unassign without full rendering, use remote XHR
        flash[:notice] = l(:notice_successful_delete)
      end
      redirect_to project_test_plan_path(id: @test_plan.id)
    rescue
      render 'forbidden', status: 404
    end
  end

  # GET /projects/:project_id/test_plans/statistics
  def statistics
    return unless authorize_with_issues_permission(params[:controller], :index)
    begin
      @test_plans = TestPlan.joins(:test_cases)
                      .joins(<<-SQL
                      LEFT JOIN (SELECT test_case_id, max(execution_date) AS execution_date
                        FROM test_case_executions GROUP BY test_case_id) AS latest_tce
                        ON latest_tce.test_case_id = test_cases.id
                      LEFT JOIN test_case_executions
                        ON latest_tce.test_case_id = test_case_executions.test_case_id
                        AND latest_tce.execution_date = test_case_executions.execution_date
                      LEFT JOIN issues ON test_case_executions.issue_id = issues.id
                      LEFT JOIN issue_statuses ON issues.status_id = issue_statuses.id
SQL
                            )
                      .where(project: @project)
                      .group(:id)
                      .select(<<-SQL
                      test_plans.id, test_plans.name, test_plans.user_id, test_plans.estimated_bug,
                      SUM(CASE WHEN test_case_executions.result IS NULL THEN 1 ELSE 0 END) AS count_not_executed,
                      SUM(CASE WHEN test_case_executions.result = '1' THEN 1 ELSE 0 END) AS count_succeeded,
                      SUM(CASE WHEN test_case_executions.result = '0' THEN 1 ELSE 0 END) AS count_failed,
                      SUM(CASE WHEN issues.id IS NOT NULL THEN 1 ELSE 0 END) AS detected_bug,
                      SUM(CASE WHEN issue_statuses.is_closed = '1' THEN 1 ELSE 0 END) AS fixed_bug
SQL
                             )
                      .order(id: :desc)
      render :statistics
    rescue
      render 'forbidden', status: 404
    end
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

  def columns
    []
  end
end
