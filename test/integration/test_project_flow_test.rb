require 'test_helper'

class TestProjectFlowTest < ActionDispatch::IntegrationTest
  fixtures :projects

  test "test_plans#index creates test_project automatically" do
    assert_difference("TestProject.count") do
      get "/projects/#{projects(:projects_001).identifier}/test_plans"
    end
    assert_response :success
  end
end
