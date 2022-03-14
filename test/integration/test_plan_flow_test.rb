require 'test_helper'

class TestPlanFlowTest < ActionDispatch::IntegrationTest
  fixtures :projects, :users, :issues, :issue_statuses

  test "add new test plan" do
    url = "/projects/#{projects(:projects_001).identifier}/test_plans"

    get "#{url}/new"
    assert_response :success

    test_plan = new_record(TestPlan) do
      assert_difference("TestPlan.count") do
        post url, params: {
               project_id: projects(:projects_001).identifier,
               test_plan: {
                 name: "dummy",
                 user: 1,
                 issue_status: 1
               }
             }
      end
    end
    assert_redirected_to :controller => 'test_plans', :action => 'show', :id => test_plan.id
  end
end
