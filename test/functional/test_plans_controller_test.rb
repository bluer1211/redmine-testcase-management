require File.expand_path('../../test_helper', __FILE__)

class TestPlansControllerTest < ActionController::TestCase
  fixtures :projects
  fixtures :test_projects

  def test_index
    get :index, params: { :project_id => test_projects(:test_projects_001).id }

    assert_response :success
    #assert_template 'index' # needs rails-controller-testing
  end
end
