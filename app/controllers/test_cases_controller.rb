class TestCasesController < ApplicationController

  include ApplicationsHelper

  before_action :find_project_id
  before_action :find_test_plan_id_if_given, :only => [:new, :create, :show, :edit, :index, :update, :destroy]
  before_action :find_test_case, :only => [:show, :edit, :update, :destroy]
  before_action :authorize_with_issues_permission, :except => [:index, :new, :create, :auto_complete]

  before_action do
    prepare_user_candidates
    prepare_issue_status_candidates
    if @test_plan
      prepare_test_plan_candidates
    end
  end

  helper :attachments
  helper :queries
  include QueriesHelper
  helper :test_cases_queries
  include TestCasesQueriesHelper

  # GET /projects/:project_id/test_cases
  # GET /projects/:project_id/test_plans/:test_plan_id/test_cases
  def index
    retrieve_query(TestCaseQuery, false)

    if @query.valid?
      respond_to do |format|
        @test_cases_export_limit = Setting.plugin_testcase_management["test_cases_export_limit"].to_i
        format.html do
          @test_case_count = @query.test_case_count
          @test_case_pages = Paginator.new @test_case_count, per_page_option, params["page"]
          if @test_plan_given
            @test_cases = @query.test_cases(test_plan_id: params[:test_plan_id],
                                            offset: @test_case_pages.offset,
                                            limit: @test_case_pages.per_page).visible
            @csv_url = project_test_plan_test_cases_path(@project, test_plan_id: params[:test_plan_id], format: "csv")
          else
            @test_cases = @query.test_cases(offset: @test_case_pages.offset,
                                            limit: @test_case_pages.per_page).visible
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
    if params.permit(:test_plan_id)[:test_plan_id]
      @test_plan = TestPlan.find(params.permit(:test_plan_id)[:test_plan_id])
    else
      @test_plan = nil
    end
  end

  # POST /projects/:project_id/test_cases
  # POST /projects/:project_id/test_plans/:test_plan_id/test_cases
  def create
    unless User.current.allowed_to?(:add_issues, @project, :global => true)
      raise ::Unauthorized
    end
    begin
      @test_case = TestCase.new(:project_id => @project.id,
                                :name => test_case_params[:name],
                                :user => User.find(test_case_params[:user]),
                                :environment => test_case_params[:environment],
                                :scenario => test_case_params[:scenario],
                                :expected => test_case_params[:expected])
      @test_case.test_plans << @test_plan if @test_plan
      if params[:attachments].present?
        @test_case.save_attachments params.require(:attachments).permit!
      end
      if @test_case.valid?
        @test_case.save
        flash[:notice] = l(:notice_successful_create)
        if @test_plan
          redirect_to project_test_plan_path(id: @test_plan.id)
        else
          redirect_to project_test_case_path(id: @test_case.id)
        end
      else
        render :new, status: :unprocessable_entity
      end
    rescue
      render :new, status: :unprocessable_entity
    end
  end

  # GET /projects/:project_id/test_cases/:id
  # GET /projects/:project_id/test_plans/:test_plan_id/test_cases/:id
  def show
    if @test_plan_given
      @test_case_execution = TestCaseExecution.find_by(test_case: @test_case,
                                                       test_plan: @test_plan)
      if @test_case_execution
        @test_case_executions = [@test_case_execution]
      else
        @test_case_executions = []
      end
    else
      @test_case_executions = @test_case.test_case_executions
    end
  end

  # GET /projects/:project_id/test_cases/:id/edit
  # GET /projects/:project_id/test_plans/:test_plan_id/test_cases/:id/edit
  def edit
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
    user = User.find(test_case_params[:user])
    update_params[:user_id] = user.id if user.present?
    if params[:attachments].present?
      @test_case.save_attachments params.require(:attachments).permit!
    end
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
    unless User.current.allowed_to?(:view_issues, @project, :global => true)
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

  private

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
      !value ? l(:label_succeed) :
        value.result ? l(:label_succeed) :
        l(:label_failure)
    when :execution_date
      !value ? l(:label_none) :
        yyyymmdd_date(value.execution_date)
    else
      super
    end
  end
end
