require 'test_helper'
require File.expand_path('../../test_helper', __FILE__)

class TestPlanFlowTest < Redmine::IntegrationTest
  fixtures :projects, :users, :issues, :members, :member_roles, :roles, :issue_statuses,
           :groups_users, :trackers, :projects_trackers, :enabled_modules
  fixtures :test_plans

  def setup
    @project = projects(:projects_001)
    generate_user_with_permissions(@project, [:view_project, :view_issues, :add_issues, :edit_issues, :delete_issues, :test_cases, :test_plans, :test_case_executions])
    log_user(@user.login, "password")
  end

  test "add new test plan" do
    url = "/projects/#{@project.identifier}/test_plans"

    get "#{url}/new"
    assert_response :success

    test_plan = new_record(TestPlan) do
      assert_difference("TestPlan.count") do
        create_test_plan
      end
    end
    assert_redirected_to :controller => 'test_plans', :action => 'show', :id => test_plan.id
  end

  test "edit test plan" do
    url = "/projects/#{@project.identifier}/test_plans/#{test_plans(:test_plans_001).id}"

    get url
    assert_response :success

    get "#{url}/edit"
    assert_response :success
  end

  test "update test plan" do
    test_plan = test_plans(:test_plans_001)
    url = "/projects/#{@project.identifier}/test_plans/#{test_plan.id}"

    get "#{url}/edit"
    assert_response :success

    put url, params: {
          test_plan: {
            name: "dummy"
          }
        }
    assert_redirected_to :controller => 'test_plans', :action => 'show', :id => test_plan.id
  end

  test "delete test plan" do
    url = "/projects/#{@project.identifier}/test_plans/#{test_plans(:test_plans_001).id}"
    get url
    assert_response :success

    delete url
    assert_redirected_to :controller => 'test_plans', :action => 'index'
  end

  private

  def create_test_plan(params={})
    post_params = {
      project_id: @project.identifier,
      test_plan: {
        name: "dummy",
        user: 1,
        issue_status: 1
      }
    }
    post_params.merge!(params)
    post "/projects/#{@project.identifier}/test_plans", params: post_params
  end
end
