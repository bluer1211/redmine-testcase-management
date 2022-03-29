class TestCasesController < ApplicationController

  include ApplicationsHelper

  before_action :find_project_id, :only => [:new, :show, :edit, :index, :update, :destroy]
  before_action :find_test_plan_id_if_given, :only => [:new, :show, :edit, :index, :update, :destroy]
  before_action :find_test_case, :only => [:show, :edit, :update, :destroy]

  before_action do
    prepare_user_candidates
    prepare_issue_status_candidates
    if @test_plan
      prepare_test_plan_candidates
    end
  end

  helper :attachments

  # GET /projects/:project_id/test_cases
  # GET /projects/:project_id/test_plans/:test_plan_id/test_cases
  def index
    if params[:test_plan_id].present?
      if @test_plan
        @test_cases = @test_plan.test_cases
      else
        redirect_to project_test_plans_path
      end
    else
      @test_cases = TestCase.where(project_id: @project.id)
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
    begin
      strong_params = params.permit(:project_id, :test_plan_id)
      find_project(strong_params[:project_id])
      @test_case = TestCase.new(:project_id => @project.id,
                                :name => test_case_params[:name],
                                :scheduled_date => test_case_params[:scheduled_date],
                                :user => User.find(test_case_params[:user]),
                                :environment => test_case_params[:environment],
                                :scenario => test_case_params[:scenario],
                                :expected => test_case_params[:expected])
      if strong_params[:test_plan_id].present?
        @test_case.test_plans << TestPlan.find(strong_params[:test_plan_id])
      end
      if params[:attachments].present?
        @test_case.save_attachments params.require(:attachments).permit!
      end
      if @test_case.valid?
        @test_case.save
        flash[:notice] = l(:notice_successful_create)
        if params[:test_plan_id].present?
          redirect_to project_test_plan_test_case_path(test_plan_id: params[:test_plan_id], id: @test_case.id)
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
    @test_case = TestCase.find(params.permit(:id)[:id])
  end

  # GET /projects/:project_id/test_cases/:id/edit
  # GET /projects/:project_id/test_plans/:test_plan_id/test_cases/:id/edit
  def edit
    @test_case = TestCase.find(params.permit(:id)[:id])
  end

  # PUT /projects/:project_id/test_cases/:id
  # PUT /projects/:project_id/test_plans/:test_plan_id/test_cases/:id
  def update
    @test_case = TestCase.find(params.permit(:id)[:id])
    update_params = {
      name: test_case_params[:name],
      scheduled_date: test_case_params[:scheduled_date],
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
    begin
      @test_case = TestCase.find(params.permit(:id)[:id])
      if @test_case.destroy
        flash[:notice] = l(:notice_successful_delete)
        if params[:test_plan_id].present?
          redirect_to project_test_plan_test_cases_path(test_plan_id: params[:test_plan_id])
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
                                      :scheduled_date,
                                      :environment,
                                      :scenario,
                                      :expected)
  end
end
