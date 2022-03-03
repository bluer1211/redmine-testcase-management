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

  private

  def permit_param(symbol)
    params.permit(symbol)[symbol]
  end

  def test_case_execution_params
    params.require(:test_case_execution).permit(:project_id,
                                                :test_project_id,
                                                :test_plan_id,
                                                :test_case_id,
                                                :name,
                                                :user,
                                                :execution_date,
                                                :comment,
                                                :result,
                                                :issue)
  end
end
