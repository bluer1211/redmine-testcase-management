require File.expand_path('../../test_helper', __FILE__)

class TestCasesControllerTest < ActionController::TestCase
  fixtures :projects, :users, :issue_statuses
  fixtures :test_projects, :test_plans, :test_cases, :test_case_executions

  include ApplicationsHelper

  NONEXISTENT_PROJECT_ID = 404
  NONEXISTENT_TEST_PLAN_ID = 404

  class Index < self
    def test_index
      get :index, params: {
            project_id: projects(:projects_002).identifier,
            test_plan_id: test_plans(:test_plans_003).id
          }
      assert_response :success
      # match all test cases
      assert_select "tbody tr", 3
      cases = []
      assert_select "tbody tr td:first-child" do |tds|
        tds.each do |td|
          cases << td.text
        end
      end
      assert_equal test_cases.pluck(:name), cases
      columns = []
      assert_select "thead tr:first-child th" do |ths|
        ths.each do |th|
          columns << th.text
        end
      end
      assert_equal [I18n.t(:field_name),
                    I18n.t(:field_status),
                    I18n.t(:field_user),
                    I18n.t(:field_scheduled_date),
                    I18n.t(:field_environment),
                    I18n.t(:field_scenario),
                    I18n.t(:field_expected)
                   ],
                   columns
      assert_select "div#content div.contextual a:first-child" do |a|
        assert_equal new_project_test_plan_test_case_path(project_id: projects(:projects_002).identifier), a.first.attributes["href"].text
        assert_equal I18n.t(:label_test_case_new), a.text
      end
    end

    def test_index_with_nonexistent_project
      get :index, params: {
            project_id: NONEXISTENT_PROJECT_ID,
            test_plan_id: test_plans(:test_plans_003).id
          }
      assert_response :missing
      assert_equal I18n.t(:error_project_not_found), flash[:error]
      assert_select "div#content a" do |link|
        link.each do |a|
          assert_equal projects_path, a.attributes["href"].text
        end
      end
    end

    def test_index_with_nonexistent_test_plan
      get :index, params: {
            project_id: projects(:projects_002).identifier,
            test_plan_id: NONEXISTENT_TEST_PLAN_ID
          }
      assert_response :missing
      assert_equal I18n.t(:error_test_plan_not_found), flash[:error]
      assert_select "div#content a" do |link|
        link.each do |a|
          assert_equal project_test_plans_path, a.attributes["href"].text
        end
      end
    end
  end

  class Create < self
    def test_create
      assert_difference("TestCase.count") do
        post :create, params: { project_id: projects(:projects_001).identifier,
                                test_plan_id: test_plans(:test_plans_001).id,
                                test_case: { test_plan_id: test_plans(:test_plans_001).id,
                                             name: "test", scenario: "dummy", expected: "dummy", environment: "dummy",
                                             user: 2, issue_status: 1 } }
      end
      assert_equal I18n.t(:notice_successful_create), flash[:notice]
      assert_redirected_to project_test_plan_test_case_path(:id => TestCase.last.id)
    end

    def test_create_with_nonexistent_project
      assert_no_difference("TestCase.count") do
        post :create, params: { project_id: NONEXISTENT_PROJECT_ID,
                                test_plan_id: test_plans(:test_plans_001).id,
                                test_case: { test_plan_id: test_plans(:test_plans_001).id,
                                             name: "test", scenario: "dummy", expected: "dummy", environment: "dummy",
                                             user: 2, issue_status: 1 } }
      end
      assert_response :unprocessable_entity
    end

    def test_create_with_nonexistent_test_plan
      assert_no_difference("TestCase.count") do
        post :create, params: { project_id: projects(:projects_001).identifier,
                                test_plan_id: test_plans(:test_plans_001).id,
                                test_case: { test_plan_id: NONEXISTENT_TEST_PLAN_ID,
                                             name: "test", scenario: "dummy", expected: "dummy", environment: "dummy",
                                             user: 2, issue_status: 1 } }
      end
      assert_response :unprocessable_entity
    end

    def test_create_with_missing_params
      assert_no_difference("TestCase.count") do
        post :create, params: { project_id: projects(:projects_001).identifier,
                                test_plan_id: test_plans(:test_plans_001).id,
                                test_case: { test_plan_id: test_plans(:test_plans_001).id,
                                             name: "test",
                                             user: 2, issue_status: 1 } }
      end
      assert_response :unprocessable_entity
    end
  end

  class Show < self
    def test_show
    end

    def test_show_with_nonexistent_project
      get :show, params: { project_id: NONEXISTENT_PROJECT_ID,
                           test_plan_id: test_plans(:test_plans_002).id,
                           id: test_cases(:test_cases_001).id,
                         }
      assert_response :missing
      assert_equal I18n.t(:error_project_not_found), flash[:error]
    end

    def test_show_with_nonexistent_test_plan
      get :show, params: { project_id: projects(:projects_002).identifier,
                           test_plan_id: NONEXISTENT_TEST_PLAN_ID,
                           id: test_cases(:test_cases_001).id,
                         }
      assert_response :missing
      assert_equal I18n.t(:error_test_plan_not_found), flash[:error]
    end

    def test_show_with_nonexistent_test_case
    end
  end

  class Edit < self

    def test_edit
    end

    def test_edit_with_nonexistent_project
    end

    def test_edit_with_nonexistent_test_plan
    end

    def test_edit_with_nonexistent_test_case
    end
  end

  class Update < self
    def test_update
    end
  end

  class Destroy < self
    def test_destroy
    end

    def test_destroy_with_nonexistent_project
    end

    def test_destroy_with_nonexistent_test_plan
    end

    def test_destroy_with_nonexistent_test_case
    end

    def test_destroy_dependent_test_case_executions
    end
  end
end
