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
  end
end
