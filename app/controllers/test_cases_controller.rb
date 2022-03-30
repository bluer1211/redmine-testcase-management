class TestCasesController < ApplicationController

  include ApplicationsHelper

  before_action :find_project_id
  before_action :find_test_plan_id_if_given, :only => [:new, :create, :show, :edit, :index, :update, :destroy]
  before_action :find_test_case, :only => [:show, :edit, :update, :destroy]
  before_action :authorize_with_issues_permission, :except => [:index, :new, :create]

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
      @test_case_count = @query.test_case_count
      @test_case_pages = Paginator.new @test_case_count, per_page_option, params['page']
      if @test_plan_given
        @test_cases = @query.test_cases(test_plan_id: params[:test_plan_id],
                                        offset: @test_case_pages.offset,
                                        limit: @test_case_pages.per_page).visible
      else
        @test_cases = @query.test_cases(offset: @test_case_pages.offset,
                                        limit: @test_case_pages.per_page).visible
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
          redirect_to project_test_plan_test_case_path(id: @test_case.id)
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
        redirect_to project_test_plan_test_case_path(test_plan_id: params[:test_plan_id])
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
    raise ActiveRecord::RecordNotFound.new unless @test_case.visible?
    raise ::Unauthorized unless @test_case.deletable?
    begin
      if @test_case.destroy
        flash[:notice] = l(:notice_successful_delete)
        if params[:test_plan_id].present?
          redirect_to project_test_plan_test_cases_path(test_plan_id: params.permit(:test_plan_id)[:test_plan_id])
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

  private

  def test_case_params
    params.require(:test_case).permit(:project_id,
                                      :test_plan_id,
                                      :name,
                                      :user,
                                      :environment,
                                      :scenario,
                                      :expected)
  end
end
