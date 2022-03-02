require File.expand_path('../../test_helper', __FILE__)

class TestPlansControllerTest < ActionController::TestCase
  fixtures :projects, :users, :issue_statuses
  fixtures :test_projects, :test_plans, :test_cases, :test_case_executions

  def test_index
    get :index, params: { :project_id => test_projects(:test_projects_001).id }

    assert_response :success
    #assert_template 'index' # needs rails-controller-testing
  end

  def test_create_test_plan
    assert_difference("TestPlan.count") do
      project_id = test_projects(:test_projects_002).project_id
      post :create, params: { project_id: project_id, test_plan: { name: "test", user: 2, issue_status: 1 } }
    end
    assert_redirected_to project_test_plan_path(:id => TestPlan.last.id)
  end

  def test_create_without_test_plan_name
    assert_no_difference("TestPlan.count") do
      project_id = test_projects(:test_projects_002).project_id
      post :create, params: { project_id: project_id, test_plan: { user: 2, issue_status: 1 } }
    end
    assert_response :unprocessable_entity
  end
end
