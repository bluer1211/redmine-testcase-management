require 'test_helper'
require File.expand_path('../../test_helper', __FILE__)

class TestCaseExecutionFlowTest < Redmine::IntegrationTest
  fixtures :projects, :users, :issues, :members, :member_roles, :roles, :issue_statuses,
           :groups_users, :trackers, :projects_trackers, :enabled_modules
  fixtures :test_plans, :test_cases, :test_case_executions

  def setup
    activate_module_for_projects
    @project = projects(:projects_003)
    @test_plan = test_plans(:test_plans_003)
    @test_case = test_cases(:test_cases_002)
    generate_user_with_permissions(@project, [:view_project, :view_issues, :add_issues, :edit_issues, :delete_issues, :test_cases, :test_plans, :test_case_executions])
    log_user(@user.login, "password")
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
    assert_redirected_to controller: "test_plans",
                         action: "show",
                         id: @test_plan.id
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
            comment: "dummy",
            execution_date: "2022-01-01"
          }
        }
    assert_redirected_to controller: "test_cases",
                         action: "show",
                         test_plan_id: @test_plan.id,
                         id: @test_case.id
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
        comment: "dummy",
        execution_date: "2022-01-01"
      }
    }
    post_params.merge!(params)
    post "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions", params: post_params
  end
end
