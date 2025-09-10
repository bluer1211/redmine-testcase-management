require 'test_helper'
require File.expand_path('../../test_helper', __FILE__)

class TestCaseFlowTest < Redmine::IntegrationTest
  fixtures :projects, :users, :issues, :members, :member_roles, :roles, :issue_statuses,
           :groups_users, :trackers, :projects_trackers, :enabled_modules
  fixtures :test_plans, :test_cases, :test_case_test_plans

  def setup
    activate_module_for_projects
    @project = projects(:projects_003)
    @test_plan = test_plans(:test_plans_002)
    @base_url = "/projects/#{@project.identifier}"
  end

  test "add new test case" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :add_issues, :edit_issues, :delete_issues, :add_test_cases])
    log_user(@user.login, "password")

    get "#{@base_url}/test_cases/new"
    assert_response :success

    test_case = new_record(TestCase) do
      assert_difference("TestCase.count") do
        create_test_case
      end
    end
    assert_redirected_to :controller => "test_cases", :action => "show", :id => test_case.id
  end

  test "add new test case with a test plan" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :add_issues, :view_test_plans, :add_test_cases])
    log_user(@user.login, "password")

    @base_url = "#{@base_url}/test_plans/#{@test_plan.id}"

    get "#{@base_url}/test_cases/new"
    assert_response :success

    test_case = new_record(TestCase) do
      assert_difference("TestCase.count") do
        create_test_case(test_plan_id: @test_plan.id)
      end
    end
    assert_redirected_to :controller => "test_plans", :action => "show", :id => @test_plan.id
  end

  test "edit test case" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :edit_issues, :edit_test_cases])
    log_user(@user.login, "password")

    test_case = test_cases(:test_cases_001)
    url = "/projects/#{@project.identifier}/test_cases/#{test_case.id}"

    get url
    assert_response :success

    get "#{url}/edit"
    assert_response :success
  end

  test "edit test case with a test plan" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :edit_issues, :view_test_plans, :edit_test_cases])
    log_user(@user.login, "password")

    test_case = test_cases(:test_cases_001)
    url = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{test_case.id}"

    get url
    assert_response :success

    get "#{url}/edit"
    assert_response :success
  end

  test "update test case" do
    test_case = test_cases(:test_cases_001)
    generate_user_with_permissions(@project, [:view_project, :view_issues, :edit_issues, :edit_test_cases])
    log_user(@user.login, "password")

    url = "/projects/#{@project.identifier}/test_cases/#{test_case.id}"

    get "#{url}/edit"
    assert_response :success

    put url, params: {
          project_id: @project_id,
          test_case: {
            name: "dummy",
            user: 1,
            issue_status: 1,
            scenario: "dummy",
            expected: "dummy",
            environment: "dummy"
          }
        }
    assert_redirected_to :controller => "test_cases", :action => "show", :id => test_case.id
  end

  test "update test case with a test plan" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :edit_issues, :view_test_plans, :edit_test_cases])
    log_user(@user.login, "password")

    test_case = test_cases(:test_cases_001)
    url = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{test_case.id}"

    get "#{url}/edit"
    assert_response :success

    put url, params: {
          project_id: @project_id,
          test_plan_id: @test_plan.id,
          test_case: {
            name: "dummy",
            user: 1,
            issue_status: 1,
            scenario: "dummy",
            expected: "dummy",
            environment: "dummy"
          }
        }
    assert_redirected_to :controller => "test_plans", :action => "show", :id => @test_plan.id
  end

  test "delete test case" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :delete_issues, :delete_test_cases, :view_test_plans])
    log_user(@user.login, "password")

    test_case = test_cases(:test_cases_001)
    url = "/projects/#{@project.identifier}/test_cases/#{test_case.id}"
    get url
    assert_response :success

    delete url
    assert_redirected_to :controller => "test_cases", :action => "index"
  end

  test "delete test case with a test plan" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :delete_issues, :delete_test_cases, :view_test_plans])
    log_user(@user.login, "password")

    test_case = test_cases(:test_cases_001)
    url = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{test_case.id}"
    get url
    assert_response :success

    delete url
    assert_redirected_to :controller => "test_plans", :action => "show", :id => @test_plan.id
  end

  private

  def create_test_case(params={})
    post_params = {
      project_id: @project.identifier,
      test_case: {
        name: "dummy",
        user: 1,
        issue_status: 1,
        scenario: "dummy",
        expected: "dummy",
        environment: "dummy"
      }
    }
    post_params.merge!(params)
    post "#{@base_url}/test_cases", params: post_params
  end
end
