require 'test_helper'

class TestPlanFlowTest < ActionDispatch::IntegrationTest
  fixtures :projects, :users, :issues, :issue_statuses

  test "add new test plan" do
    url = "/projects/#{projects(:projects_001).identifier}/test_plans"

    get "#{url}/new"
    assert_response :success

    test_plan = new_record(TestPlan) do
      assert_difference("TestPlan.count") do
        create_test_plan
      end
    end
    assert_redirected_to :controller => 'test_plans', :action => 'show', :id => test_plan.id
  end
  private

  def create_test_plan(params={})
    post_params = {
      project_id: projects(:projects_001).identifier,
      test_plan: {
        name: "dummy",
        user: 1,
        issue_status: 1
      }
    }
    post_params.merge!(params)
    post "/projects/#{projects(:projects_001).identifier}/test_plans", params: post_params
  end
end
