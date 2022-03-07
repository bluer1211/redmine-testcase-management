require File.expand_path('../../test_helper', __FILE__)

class TestPlansControllerTest < ActionController::TestCase
  fixtures :projects, :users, :issue_statuses
  fixtures :test_projects, :test_plans, :test_cases, :test_case_executions

  def setup
    # FIXME: use test_plan.test_project.project_id
    @project_id = test_projects(:test_projects_002)
  end

  def test_index
    get :index, params: { project_id: @project_id }

    assert_response :success
    # show all test plans
    assert_select "tbody tr", 3
    plans = []
    assert_select "tbody tr td:first-child" do |tds|
      tds.each do |td|
        plans << td.text
      end
    end
    assert_equal plans, test_plans.pluck(:name)
  end

  def test_show
    test_plan = test_plans(:test_plans_002)
    get :show, params: { project_id: @project_id, id: test_plan.id }

    assert_response :success
    assert_select "tbody tr", 1
  end

  def test_destroy
    test_plan = test_plans(:test_plans_002)
    assert_difference("TestPlan.count", -1) do
      delete :destroy, params: { project_id: @project_id, id: test_plan.id }
    end
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
