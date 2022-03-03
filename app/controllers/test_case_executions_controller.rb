class TestCaseExecutionsController < ApplicationController

  include ApplicationsHelper

  before_action do
    prepare_user_candidates
  end

  def index
    find_test_project(params.permit(:project_id)[:project_id])
    # FIXME: limit project
    @test_case_executions = TestCaseExecution.all
  end

  def new
    find_test_project(params.permit(:project_id)[:project_id])
    @test_case_execution = TestCaseExecution.new
    # FIXME:
    # @test_plan = @test_case_execution.test_plan
    # @test_case = @test_case_execution.test_case
    @test_plan = TestPlan.find(permit_param(:test_plan_id))
    @test_case = TestCase.find(permit_param(:test_case_id))
  end

  def create
    create_params = {
      result: test_case_execution_params[:result],
      user: User.find(test_case_execution_params[:user]),
      comment: test_case_execution_params[:comment],
      execution_date: test_case_execution_params[:execution_date],
      test_plan: TestPlan.find(permit_param(:test_plan_id)),
      test_case: TestCase.find(permit_param(:test_case_id))
    }
    if test_case_execution_params[:issue_id]
      create_params[:issue_id] = test_case_execution_params[:issue_id]
    end
    @test_case_execution = TestCaseExecution.new(create_params)
    if @test_case_execution.valid?
      @test_case_execution.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_test_plan_test_case_test_case_execution_path(:id => @test_case_execution.id)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    find_test_project(params.permit(:project_id)[:project_id])
    @test_case_execution = TestCaseExecution.find(params.permit(:id)[:id])
    # FIXME:
    @test_plan = TestPlan.find(permit_param(:test_plan_id))
    @test_case = TestCase.find(permit_param(:test_case_id))
  end

  def edit
    find_test_project(params.permit(:project_id)[:project_id])
    @test_case_execution = TestCaseExecution.find(params.permit(:id)[:id])
    # FIXME:
    @test_plan = TestPlan.find(permit_param(:test_plan_id))
    @test_case = TestCase.find(permit_param(:test_case_id))
  end

  def update
    @test_case_execution = TestCaseExecution.find(params.permit(:id)[:id])
    update_params = {
      execution_date: test_case_execution_params[:execution_date],
      result: test_case_execution_params[:result],
      comment: test_case_execution_params[:comment],
    }
    user = User.find(test_case_execution_params[:user])
    update_params[:user] = user if user.present?
    if test_case_execution_params[:issue].present?
      issue = Issue.find(test_case_execution_params[:issue])
      update_params[:issue] = issue if issue.present?
    end
    if @test_case_execution.update(update_params)
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_test_plan_test_case_test_case_execution_path
    else
      flash.now[:error] = l(:error_update_failure)
      render :edit
    end
  end

  def destroy
    begin
      @test_case_execution = TestCaseExecution.find(params.permit(:id)[:id])
      if @test_case_execution.delete
        flash[:notice] = l(:notice_successful_delete)
        redirect_to project_test_plan_test_case_test_case_executions_path
      else
        flash.now[:error] = l(:error_delete_failure)
        render :show
      end
    rescue
      flash.now[:error] = l(:error_delete_failure)
      redirect_to project_test_plan_test_case_test_case_executions_path
    end
  end

  private

  def permit_param(symbol)
    params.permit(symbol)[symbol]
  end

  def test_case_execution_params
    params.require(:test_case_execution).permit(:project_id,
                                                :test_project_id,
                                                :test_plan_id,
                                                :test_case_id,
                                                :user,
                                                :execution_date,
                                                :comment,
                                                :result,
                                                :issue)
  end
end
