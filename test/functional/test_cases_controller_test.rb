require File.expand_path('../../test_helper', __FILE__)

class TestCasesControllerTest < ActionController::TestCase
  fixtures :projects, :users, :issue_statuses
  fixtures :test_projects, :test_plans, :test_cases, :test_case_executions

  include ApplicationsHelper

  NONEXISTENT_PROJECT_ID = 404
  NONEXISTENT_TEST_PLAN_ID = 404
  NONEXISTENT_TEST_CASE_ID = 404

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
      assert_flash_error I18n.t(:error_project_not_found)
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
      assert_flash_error I18n.t(:error_test_plan_not_found)
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
      test_case = test_cases(:test_cases_002)
      test_plan = test_plans(:test_plans_003)
        get :show, params: { project_id: projects(:projects_002).identifier,
                             test_plan_id: test_plan.id,
                             id: test_case.id,
                           }
      assert_response :success
      assert_select "h2.inline-flex" do |h2|
        assert_equal "#{I18n.t(:label_test_cases)} \##{test_case.id}", h2.text
      end
      assert_select "div.subject div h3" do |h3|
        assert_equal test_case.name, h3.text
      end
      assert_select "div#test_plan" do |div|
        assert_equal test_case.test_plan.name, div.text
      end
      assert_select "div#issue_status" do |div|
        assert_equal test_case.issue_status.name, div.text
      end
      assert_select "div#user" do |div|
        assert_equal test_case.user.name, div.text
      end
      assert_select "div#scheduled_date" do |div|
        assert_equal yyyymmdd_date(test_case.scheduled_date), div.text
      end
      assert_select "div#environment" do |div|
        assert_equal test_case.environment, div.text
      end
      assert_select "div#scenario div.wiki" do |div|
        assert_equal test_case.scenario, div.text.strip
      end
      assert_select "div#expected div.wiki" do |div|
        assert_equal test_case.expected, div.text.strip
      end
      assert_select "div#test_case_execution_tree div.contextual a:first-child" do |a|
        assert_equal new_project_test_plan_test_case_test_case_execution_path(test_plan_id: test_plan.id, test_case_id: test_case.id),
                     a.first.attributes["href"].text
        assert_equal I18n.t(:label_added), a.text
      end
      assert_select "div#test_case_execution_tree tbody tr", 1
    end

    def test_show_with_nonexistent_project
      get :show, params: { project_id: NONEXISTENT_PROJECT_ID,
                           test_plan_id: test_plans(:test_plans_002).id,
                           id: test_cases(:test_cases_001).id,
                         }
      assert_response :missing
      assert_flash_error I18n.t(:error_project_not_found)
    end

    def test_show_with_nonexistent_test_plan
      get :show, params: { project_id: projects(:projects_002).identifier,
                           test_plan_id: NONEXISTENT_TEST_PLAN_ID,
                           id: test_cases(:test_cases_001).id,
                         }
      assert_response :missing
      assert_flash_error I18n.t(:error_test_plan_not_found)
    end

    def test_show_with_nonexistent_test_case
      get :show, params: { project_id: projects(:projects_002).identifier,
                           test_plan_id: test_plans(:test_plans_002).id,
                           id: NONEXISTENT_TEST_CASE_ID,
                         }
      assert_response :missing
      assert_flash_error I18n.t(:error_test_case_not_found)
    end
  end

  class Edit < self

    def test_edit
      test_plan = test_plans(:test_plans_002)
      test_case = test_cases(:test_cases_001)
      get :edit, params: { project_id: projects(:projects_002).identifier,
                           test_plan_id: test_plan.id,
                           id: test_case.id
                         }
      assert_response :success
      assert_select "div#content h2" do |h2|
        assert_equal "#{I18n.t(:permission_edit_test_case)} #{test_case.name}", h2.text
      end
      assert_select "input[name='test_case[name]']" do |input|
        assert_equal test_case.name, input.first.attributes["value"].value
      end
      assert_select "select[name='test_case[issue_status]']" do |select|
        select.first.children.each do |option|
          assert_equal test_case.issue_status.name, option.text if option.attributes["selected"]
        end
      end
      assert_select "select[name='test_case[user]']" do |select|
        select.first.children.each do |option|
          assert_equal test_case.user.name, option.text if option.attributes["selected"]
        end
      end
      assert_select "input[name='test_case[scheduled_date]']" do |input|
        assert_equal yyyymmdd_date(test_case.scheduled_date, "-"), input.first.attributes["value"].value
      end
      assert_select "input[name='test_case[environment]']" do |input|
        assert_equal test_case.environment, input.first.attributes["value"].value
      end
      assert_select "textarea[name='test_case[scenario]']" do |textarea|
        assert_equal test_case.scenario, textarea.text.strip
      end
      assert_select "textarea[name='test_case[expected]']" do |textarea|
        assert_equal test_case.expected, textarea.text.strip
      end
    end

    def test_edit_with_nonexistent_project
      get :edit, params: { project_id: NONEXISTENT_PROJECT_ID,
                           test_plan_id: test_plans(:test_plans_002).id,
                           id: test_cases(:test_cases_001).id,
                         }
      assert_response :missing
      assert_flash_error I18n.t(:error_project_not_found)
    end

    def test_edit_with_nonexistent_test_plan
      get :edit, params: { project_id: projects(:projects_002).identifier,
                           test_plan_id: NONEXISTENT_TEST_PLAN_ID,
                           id: test_cases(:test_cases_001).id,
                         }
      assert_response :missing
      assert_flash_error I18n.t(:error_test_plan_not_found)
    end

    def test_edit_with_nonexistent_test_case
      get :edit, params: { project_id: projects(:projects_002).identifier,
                           test_plan_id: test_plans(:test_plans_002).id,
                           id: NONEXISTENT_TEST_CASE_ID,
                         }
      assert_response :missing
      assert_flash_error I18n.t(:error_test_case_not_found)
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
