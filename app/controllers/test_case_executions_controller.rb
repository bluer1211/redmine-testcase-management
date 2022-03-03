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
    @test_case_execution = TestCaseExecution.new(:result => test_case_execution_params[:result],
                                                 :user => User.find(test_case_execution_params[:user]),
                                                 :comment => test_case_execution_params[:comment],
                                                 :execution_date => test_case_execution_params[:execution_date],
                                                 :test_plan => TestPlan.find(permit_param(:test_plan_id)),
                                                 :test_case => TestCase.find(permit_param(:test_case_id)))
    if @test_case_execution.valid?
      @test_case_execution.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_test_plan_test_case_test_case_execution_path(:id => @test_case_execution.id)
    else
      render :new, status: :unprocessable_entity
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
