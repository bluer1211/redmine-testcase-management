require 'test_helper'
require File.expand_path('../../test_helper', __FILE__)

class TestCaseExecutionFlowTest < ActionDispatch::IntegrationTest
  fixtures :projects, :users, :issues, :issue_statuses
  fixtures :test_plans, :test_cases, :test_case_executions

  def setup
    @project = projects(:projects_003)
    @test_plan = test_plans(:test_plans_003)
    @test_case = test_cases(:test_cases_002)
    login_with_permissions(@project, [:view_project, :view_issues, :add_issues, :edit_issues, :delete_issues])
  end

  test "add new test case execution" do
    url = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions"

    get "#{url}/new"
    assert_response :success

    test_case_execution = new_record(TestCaseExecution) do
      assert_difference("TestCaseExecution.count") do
        create_test_case_execution
      end
    end
    assert_redirected_to :controller => 'test_case_executions', :action => 'show', :id => test_case_execution.id
  end

  test "edit test case execution" do
    test_case_execution = test_case_executions(:test_case_executions_001)
    url = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions/#{test_case_execution.id}"

    get url
    assert_response :success

    get "#{url}/edit"
    assert_response :success
  end

  test "update test case" do
    test_case_execution = test_case_executions(:test_case_executions_001)
    url = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions/#{test_case_execution.id}"

    get "#{url}/edit"
    assert_response :success

    put url, params: {
          project_id: @project_id,
          test_plan_id: @test_plan.id,
          test_case_id: @test_case.id,
          test_case_execution: {
            result: true,
            user: 1,
            comment: "dummy"
          }
        }
    assert_redirected_to :controller => 'test_case_executions', :action => 'show', :id => test_case_execution.id
  end

  test "delete test plan" do
    test_case_execution = test_case_executions(:test_case_executions_001)
    url = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions/#{test_case_execution.id}"
    get url
    assert_response :success

    delete url
    assert_redirected_to :controller => 'test_case_executions', :action => 'index'
  end

  private

  def create_test_case_execution(params={})
    post_params = {
      project_id: @project.identifier,
      test_plan_id: @test_plan.id,
      test_case_id: @test_case.id,
      test_case_execution: {
        user: 1,
        result: true,
        comment: "dummy"
      }
    }
    post_params.merge!(params)
    post "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions", params: post_params
  end
end
