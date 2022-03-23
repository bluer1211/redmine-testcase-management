require 'test_helper'

class TestCaseFlowTest < ActionDispatch::IntegrationTest
  fixtures :projects, :users, :issues, :issue_statuses
  fixtures :test_plans, :test_cases, :test_case_test_plans

  def setup
    @project = projects(:projects_003)
    @test_plan = test_plans(:test_plans_002)
  end

  test "add new test case" do
    url = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases"

    get "#{url}/new"
    assert_response :success

    test_case = new_record(TestCase) do
      assert_difference("TestCase.count") do
        create_test_case
      end
    end
    assert_redirected_to :controller => 'test_cases', :action => 'show', :id => test_case.id
  end

  test "edit test case" do
    test_case = test_cases(:test_cases_001)
    url = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{test_case.id}"

    get url
    assert_response :success

    get "#{url}/edit"
    assert_response :success
  end

  test "update test case" do
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
    assert_redirected_to :controller => 'test_cases', :action => 'show', :id => test_case.id
  end

  test "delete test plan" do
    test_case = test_cases(:test_cases_001)
    url = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{test_case.id}"
    get url
    assert_response :success

    delete url
    assert_redirected_to :controller => 'test_cases', :action => 'index'
  end

  private

  def create_test_case(params={})
    post_params = {
      project_id: @project.identifier,
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
    post_params.merge!(params)
    post "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases", params: post_params
  end
end
