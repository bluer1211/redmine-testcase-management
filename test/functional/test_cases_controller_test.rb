require File.expand_path('../../test_helper', __FILE__)

class TestCasesControllerTest < ActionController::TestCase
  fixtures :projects, :users, :issues, :issue_statuses, :roles, :members, :member_roles,
           :groups_users, :trackers, :projects_trackers, :enabled_modules
  fixtures :test_plans, :test_cases, :test_case_executions, :test_case_test_plans

  include ApplicationsHelper

  NONEXISTENT_PROJECT_ID = 404
  NONEXISTENT_TEST_PLAN_ID = 404
  NONEXISTENT_TEST_CASE_ID = 404

  class Independent < self
    class Index < self
      def test_index
        get :index, params: {
              project_id: projects(:projects_003).identifier,
            }
        assert_response :success
        # match all test cases
        assert_select "tbody tr", 3
        assert_equal test_cases(:test_cases_003, :test_cases_002, :test_cases_001).pluck(:id),
                     css_select("table#test_cases_list tbody tr td.id").map(&:text).map(&:to_i)
        columns = []
        assert_select "thead tr:first-child th" do |ths|
          ths.each do |th|
            columns << th.text
          end
        end
        assert_equal ['#',
                      I18n.t(:field_name),
                      I18n.t(:field_environment),
                      I18n.t(:field_user),
                      I18n.t(:field_scenario),
                      I18n.t(:field_expected)
                     ],
                     columns
        assert_select "div#content div.contextual a:first-child" do |a|
          assert_equal new_project_test_case_path(project_id: projects(:projects_003).identifier), a.first.attributes["href"].text
          assert_equal I18n.t(:label_test_case_new), a.text
        end
      end

      def test_index_with_nonexistent_project
        get :index, params: {
              project_id: NONEXISTENT_PROJECT_ID,
            }
        assert_response :missing
        assert_flash_error I18n.t(:error_project_not_found)
        assert_select "div#content a" do |link|
          link.each do |a|
            assert_equal projects_path, a.attributes["href"].text
          end
        end
      end
    end

    class Create < self
      def test_create
        assert_difference("TestCase.count") do
          post :create, params: {
                 project_id: projects(:projects_001).identifier,
                 test_case: {
                   name: "test", scenario: "dummy", expected: "dummy", environment: "dummy",
                   user: 2
                 }
               }
        end
        assert_equal I18n.t(:notice_successful_create), flash[:notice]
        assert_redirected_to project_test_case_path(:id => TestCase.last.id)
      end

      def test_create_with_nonexistent_project
        assert_no_difference("TestCase.count") do
          post :create, params: {
                 project_id: NONEXISTENT_PROJECT_ID,
                 test_case: {
                   name: "test", scenario: "dummy", expected: "dummy", environment: "dummy",
                   user: 2
                 }
               }
        end
        assert_response :unprocessable_entity
      end

      def test_create_with_missing_params
        assert_no_difference("TestCase.count") do
          post :create, params: {
                 project_id: projects(:projects_001).identifier,
                 test_case: {
                   name: "test",
                   user: 2
                 }
               }
        end
        assert_response :unprocessable_entity
      end
    end

    class Show < self
      def test_show
        test_case = test_cases(:test_cases_002)
        get :show, params: {
              project_id: projects(:projects_002).identifier,
              id: test_case.id
            }
        assert_response :success
        assert_select "h2.inline-flex" do |h2|
          assert_equal "#{I18n.t(:label_test_cases)} \##{test_case.id}", h2.text
        end
        assert_select "div.subject div h3" do |h3|
          assert_equal test_case.name, h3.text
        end
        assert_not_select "div#test_plan"
        assert_select "div#user" do |div|
          assert_equal test_case.user.name, div.text
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
        assert_not_select "div#test_case_execution_tree div.contextual a:first-child",
                          { text: I18n.t(:label_test_case_execution_new) }
        assert_select "div#test_case_execution_tree tbody tr", 1
      end

      def test_show_with_nonexistent_project
        get :show, params: {
              project_id: NONEXISTENT_PROJECT_ID,
              id: test_cases(:test_cases_001).id
            }
        assert_response :missing
        assert_flash_error I18n.t(:error_project_not_found)
      end

      def test_show_with_nonexistent_test_case
        get :show, params: {
              project_id: projects(:projects_002).identifier,
              id: NONEXISTENT_TEST_CASE_ID
            }
        assert_response :missing
        assert_flash_error I18n.t(:error_test_case_not_found)
      end
    end

    class Edit < self

      def test_edit
        test_case = test_cases(:test_cases_001)
        get :edit, params: {
              project_id: projects(:projects_002).identifier,
              id: test_case.id
            }
        assert_response :success
        assert_select "div#content h2" do |h2|
          assert_equal "#{I18n.t(:permission_edit_test_case)} #{test_case.name}", h2.text
        end
        assert_select "input[name='test_case[name]']" do |input|
          assert_equal test_case.name, input.first.attributes["value"].value
        end
        assert_select "select[name='test_case[user]']" do |select|
          select.first.children.each do |option|
            assert_equal test_case.user.name, option.text if option.attributes["selected"]
          end
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
        get :edit, params: {
              project_id: NONEXISTENT_PROJECT_ID,
              id: test_cases(:test_cases_001).id
            }
        assert_response :missing
        assert_flash_error I18n.t(:error_project_not_found)
      end

      def test_edit_with_nonexistent_test_case
        get :edit, params: {
              project_id: projects(:projects_002).identifier,
              id: NONEXISTENT_TEST_CASE_ID
            }
        assert_response :missing
        assert_flash_error I18n.t(:error_test_case_not_found)
      end
    end

    class Update < self
      def test_update
        test_case = test_cases(:test_cases_001)
        assert_no_difference("TestCase.count") do
          put :update, params: {
                project_id: projects(:projects_003).identifier,
                id: test_case.id,
                test_case: {
                  name: "test", scenario: "dummy", expected: "dummy", environment: "dummy",
                  user: 2
                }
              }
        end
        assert_equal I18n.t(:notice_successful_update), flash[:notice]
        assert_redirected_to project_test_case_path(:id => test_case.id)
      end

      def test_update_with_nonexistent_project
        put :update, params: {
              project_id: NONEXISTENT_PROJECT_ID,
              id: test_cases(:test_cases_001).id
            }
        assert_response :missing
        assert_flash_error I18n.t(:error_project_not_found)
      end

      def test_update_with_nonexistent_test_case
        put :update, params: {
              project_id: projects(:projects_002).identifier,
              id: NONEXISTENT_TEST_CASE_ID
            }
        assert_response :missing
        assert_flash_error I18n.t(:error_test_case_not_found)
      end

      def test_update_with_missing_params
        test_case = test_cases(:test_cases_001)
        assert_no_difference("TestCase.count") do
          put :update, params: {
                project_id: projects(:projects_003).identifier,
                id: test_case.id,
                test_case: {
                  name: "test",
                  user: 2
                }
              }
        end
        assert_response :unprocessable_entity
        assert_flash_error I18n.t(:error_update_failure)
      end
    end

    class Destroy < self
      def test_destroy
        assert_difference("TestCase.count", -1) do
          delete :destroy, params: {
                   project_id: projects(:projects_002).identifier,
                   id: test_cases(:test_cases_001).id
                 }
        end
        assert_equal I18n.t(:notice_successful_delete), flash[:notice]
        assert_redirected_to project_test_cases_path
      end

      def test_destroy_with_nonexistent_project
        assert_no_difference("TestCase.count") do
          delete :destroy, params: {
                   project_id: NONEXISTENT_PROJECT_ID,
                   id: test_cases(:test_cases_001).id
                 }
        end
        assert_response :missing
        assert_flash_error I18n.t(:error_project_not_found)
      end

      def test_destroy_with_nonexistent_test_case
        assert_no_difference("TestCase.count") do
          delete :destroy, params: {
                   project_id: projects(:projects_002).identifier,
                   id: NONEXISTENT_TEST_CASE_ID
                 }
        end
        assert_response :missing
        assert_flash_error I18n.t(:error_test_case_not_found)
      end

      def test_destroy_dependent_test_case_executions
        assert_difference("TestCase.count", -1) do
          assert_difference("TestCaseExecution.count", -1) do
            delete :destroy, params: {
                     project_id: projects(:projects_002).identifier,
                     id: test_cases(:test_cases_002).id
                   }
          end
        end
        assert_equal I18n.t(:notice_successful_delete), flash[:notice]
        assert_redirected_to project_test_cases_path
      end
    end
  end

  class AssociatedWithTestPlan < self
    class Index < self
      def test_index
        get :index, params: {
              project_id: projects(:projects_003).identifier,
              test_plan_id: test_plans(:test_plans_003).id
            }
        assert_response :success
        # match all test cases
        assert_equal test_cases(:test_cases_003, :test_cases_002).pluck(:id),
                     css_select("table#test_cases_list tbody tr td.id").map(&:text).map(&:to_i)
        columns = []
        assert_select "thead tr:first-child th" do |ths|
          ths.each do |th|
            columns << th.text
          end
        end
        assert_equal ['#',
                      I18n.t(:field_name),
                      I18n.t(:field_environment),
                      I18n.t(:field_user),
                      I18n.t(:field_scenario),
                      I18n.t(:field_expected)
                     ],
                     columns
        assert_select "div#content div.contextual a:first-child" do |a|
          assert_equal new_project_test_plan_test_case_path(project_id: projects(:projects_003).identifier), a.first.attributes["href"].text
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

      class Filter < self
        def setup
          @project = projects(:projects_003)
          @test_plan = test_plans(:test_plans_003)
          login_with_permissions(@project, [:view_project, :view_issues])
        end

        def test_index_with_invalid_filter
          get :index, params: filter_params("user_id", "=", {})
          assert_flash_error I18n.t(:error_index_failure)
          assert_response :unprocessable_entity
        end

        def test_index_with_name_filter
          get :index, params: filter_params("name", "~",
                                            { "name": [test_cases(:test_cases_002).name] })
          assert_response :success
          # test_cases_003 must be ignored
          assert_equal [test_cases(:test_cases_002).id],
                       css_select("table#test_cases_list tbody tr td.id").map(&:text).map(&:to_i)
        end

        def test_index_with_user_filter
          test_cases(:test_cases_002).update(user: users(:users_001))
          get :index, params: filter_params("user_id", "=", { "user_id": [users(:users_001).id] })
          assert_response :success
          # test_cases_003 (users_002) must be ignored
          assert_equal [test_cases(:test_cases_002).id],
                       css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
        end

        def test_index_with_environment_filter
          test_cases(:test_cases_002).update(environment: "dummy")
          get :index, params: filter_params("environment", "~",
                                            { "environment": [test_cases(:test_cases_002).environment] })
          assert_response :success
          # test_cases_003 must be ignored
          assert_equal [test_cases(:test_cases_002).id],
                       css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
        end

        def test_index_with_scenario_filter
          test_cases(:test_cases_002).update(scenario: "dummy")
          get :index, params: filter_params("scenario", "~",
                                            { "scenario": [test_cases(:test_cases_002).scenario] })
          assert_response :success
          # test_cases_003 must be ignored
          assert_equal [test_cases(:test_cases_002).id],
                       css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
        end

        def test_index_with_expected_filter
          test_cases(:test_cases_002).update(expected: "dummy")
          get :index, params: filter_params("expected", "~",
                                            { "expected": [test_cases(:test_cases_002).expected] })
          assert_response :success
          # test_cases_003 must be ignored
          assert_equal [test_cases(:test_cases_002).id],
                       css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
        end

        private

        def filter_params(field, operation, values)
          filters = {
            project_id: @project.identifier,
            test_plan_id: @test_plan.id,
            set_filter: 1,
            f: [field],
            op: {
              "#{field}" => operation
            },
            v: values,
            c: ["name", "environment", "user", "scheduled_date", "scenario", "expected"]
          }
          filters
        end
      end

      class Order < self
        def setup
          @project = projects(:projects_003)
          login_with_permissions(@project, [:view_project, :view_issues])
          @order_params = {
            project_id: @project.identifier,
            test_plan_id: test_plans(:test_plans_003),
          }
        end

        def test_id_order_by_desc
          ids = test_cases(:test_cases_003, :test_cases_002).pluck(:id)
          get :index, params: @order_params
          assert_response :success
          assert_equal ids,
                       css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
        end

        def test_id_order_by_asc
          ids = test_cases(:test_cases_002, :test_cases_003).pluck(:id)
          get :index, params: @order_params.merge({ sort: "id:asc" })
          assert_response :success
          assert_equal ids,
                       css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
        end

        def test_name_order_by_desc
          ids = test_cases(:test_cases_003, :test_cases_002).pluck(:id)
          get :index, params: @order_params.merge({ sort: "name:desc" })
          assert_response :success
          assert_equal ids,
                       css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
        end

        def test_name_order_by_asc
          ids = test_cases(:test_cases_002, :test_cases_003).pluck(:id)
          get :index, params: @order_params.merge({ sort: "name:asc" })
          assert_response :success
          assert_equal ids,
                       css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
        end

        def test_user_order_by_desc
          test_cases(:test_cases_002).update(user: users(:users_001))
          ids = test_cases(:test_cases_003, :test_cases_002).pluck(:id)
          get :index, params: @order_params.merge({ sort: "user:desc" })
          assert_response :success
          # should be listed in admin, jsmith
          assert_equal ids,
                       css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
        end

        def test_user_order_by_asc
          test_cases(:test_cases_002).update(user: users(:users_001))
          ids = test_cases(:test_cases_002, :test_cases_003).pluck(:id)
          get :index, params: @order_params.merge({ sort: "user:asc" })
          assert_response :success
          # should be listed in jsmith, admin
          assert_equal ids,
                       css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
        end

        def test_scenario_order_by_desc
          ids = test_cases(:test_cases_003, :test_cases_002).pluck(:id)
          get :index, params: @order_params.merge({ sort: "scenario:desc" })
          assert_response :success
          assert_equal ids,
                       css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
        end

        def test_scenario_order_by_asc
          ids = test_cases(:test_cases_002, :test_cases_003).pluck(:id)
          get :index, params: @order_params.merge({ sort: "scenario:asc" })
          assert_response :success
          assert_equal ids,
                       css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
        end

        def test_expected_order_by_desc
          ids = test_cases(:test_cases_003, :test_cases_002).pluck(:id)
          get :index, params: @order_params.merge({ sort: "expected:desc" })
          assert_response :success
          assert_equal ids,
                       css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
        end

        def test_expected_order_by_asc
          ids = test_cases(:test_cases_002, :test_cases_003).pluck(:id)
          get :index, params: @order_params.merge({ sort: "expected:asc" })
          assert_response :success
          assert_equal ids,
                       css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
        end
      end
    end

    class Create < self
      def test_create
        assert_difference("TestCase.count") do
          post :create, params: {
                 project_id: projects(:projects_001).identifier,
                 test_plan_id: test_plans(:test_plans_001).id,
                 test_case: {
                   name: "test", scenario: "dummy", expected: "dummy", environment: "dummy",
                   user: 2
                 }
               }
        end
        assert_equal I18n.t(:notice_successful_create), flash[:notice]
        assert_redirected_to project_test_plan_test_case_path(:id => TestCase.last.id)
      end

      def test_create_with_nonexistent_project
        assert_no_difference("TestCase.count") do
          post :create, params: {
                 project_id: NONEXISTENT_PROJECT_ID,
                 test_plan_id: test_plans(:test_plans_001).id,
                 test_case: {
                   name: "test", scenario: "dummy", expected: "dummy", environment: "dummy",
                   user: 2
                 }
               }
        end
        assert_response :unprocessable_entity
      end

      def test_create_with_nonexistent_test_plan
        assert_no_difference("TestCase.count") do
          post :create, params: {
                 project_id: projects(:projects_001).identifier,
                 test_plan_id: NONEXISTENT_TEST_PLAN_ID,
                 test_case: {
                   name: "test", scenario: "dummy", expected: "dummy", environment: "dummy",
                   user: 2
                 }
               }
        end
        assert_response :unprocessable_entity
      end

      def test_create_with_missing_params
        assert_no_difference("TestCase.count") do
          post :create, params: {
                 project_id: projects(:projects_001).identifier,
                 test_plan_id: test_plans(:test_plans_001).id,
                 test_case: {
                   name: "test",
                   user: 2
                 }
               }
        end
        assert_response :unprocessable_entity
      end
    end

    class Show < self
      def test_show
        test_case = test_cases(:test_cases_002)
        test_plan = test_plans(:test_plans_003)
        get :show, params: {
              project_id: projects(:projects_002).identifier,
              test_plan_id: test_plan.id,
              id: test_case.id
            }
        assert_response :success
        assert_select "h2.inline-flex" do |h2|
          assert_equal "#{I18n.t(:label_test_cases)} \##{test_case.id}", h2.text
        end
        assert_select "div.subject div h3" do |h3|
          assert_equal test_case.name, h3.text
        end
        assert_select "div#test_plan" do |div|
          assert_equal test_case.test_plan.name, div.text.strip
        end
        assert_select "div#user" do |div|
          assert_equal test_case.user.name, div.text
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
          assert_equal I18n.t(:label_test_case_execution_new), a.text
        end
        assert_select "div#test_case_execution_tree tbody tr", 1
      end

      def test_show_with_nonexistent_project
        get :show, params: {
              project_id: NONEXISTENT_PROJECT_ID,
              test_plan_id: test_plans(:test_plans_002).id,
              id: test_cases(:test_cases_001).id
            }
        assert_response :missing
        assert_flash_error I18n.t(:error_project_not_found)
      end

      def test_show_with_nonexistent_test_plan
        get :show, params: {
              project_id: projects(:projects_002).identifier,
              test_plan_id: NONEXISTENT_TEST_PLAN_ID,
              id: test_cases(:test_cases_001).id
            }
        assert_response :missing
        assert_flash_error I18n.t(:error_test_plan_not_found)
      end

      def test_show_with_nonexistent_test_case
        get :show, params: {
              project_id: projects(:projects_002).identifier,
              test_plan_id: test_plans(:test_plans_002).id,
              id: NONEXISTENT_TEST_CASE_ID
            }
        assert_response :missing
        assert_flash_error I18n.t(:error_test_case_not_found)
      end
    end

    class Edit < self

      def test_edit
        test_plan = test_plans(:test_plans_002)
        test_case = test_cases(:test_cases_001)
        get :edit, params: {
              project_id: projects(:projects_002).identifier,
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
        assert_select "select[name='test_case[user]']" do |select|
          select.first.children.each do |option|
            assert_equal test_case.user.name, option.text if option.attributes["selected"]
          end
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
        get :edit, params: {
              project_id: NONEXISTENT_PROJECT_ID,
              test_plan_id: test_plans(:test_plans_002).id,
              id: test_cases(:test_cases_001).id
            }
        assert_response :missing
        assert_flash_error I18n.t(:error_project_not_found)
      end

      def test_edit_with_nonexistent_test_plan
        get :edit, params: {
              project_id: projects(:projects_002).identifier,
              test_plan_id: NONEXISTENT_TEST_PLAN_ID,
              id: test_cases(:test_cases_001).id
            }
        assert_response :missing
        assert_flash_error I18n.t(:error_test_plan_not_found)
      end

      def test_edit_with_nonexistent_test_case
        get :edit, params: {
              project_id: projects(:projects_002).identifier,
              test_plan_id: test_plans(:test_plans_002).id,
              id: NONEXISTENT_TEST_CASE_ID
            }
        assert_response :missing
        assert_flash_error I18n.t(:error_test_case_not_found)
      end
    end

    class Update < self
      def test_update
        test_case = test_cases(:test_cases_001)
        test_plan = test_plans(:test_plans_002)
        assert_no_difference("TestCase.count") do
          put :update, params: {
                project_id: projects(:projects_003).identifier,
                test_plan_id: test_plan.id,
                id: test_case.id,
                test_case: {
                  test_plan_id: test_plans(:test_plans_002).id,
                  name: "test", scenario: "dummy", expected: "dummy", environment: "dummy",
                  user: 2
                }
              }
        end
        assert_equal I18n.t(:notice_successful_update), flash[:notice]
        assert_redirected_to project_test_plan_test_case_path(:id => test_case.id)
      end

      def test_update_with_nonexistent_project
        put :update, params: {
              project_id: NONEXISTENT_PROJECT_ID,
              test_plan_id: test_plans(:test_plans_002).id,
              id: test_cases(:test_cases_001).id
            }
        assert_response :missing
        assert_flash_error I18n.t(:error_project_not_found)
      end

      def test_update_with_nonexistent_test_plan
        put :update, params: {
              project_id: projects(:projects_002).identifier,
              test_plan_id: NONEXISTENT_TEST_PLAN_ID,
              id: test_cases(:test_cases_001).id
            }
        assert_response :missing
        assert_flash_error I18n.t(:error_test_plan_not_found)
      end

      def test_update_with_nonexistent_test_case
        put :update, params: {
              project_id: projects(:projects_002).identifier,
              test_plan_id: test_plans(:test_plans_002).id,
              id: NONEXISTENT_TEST_CASE_ID
            }
        assert_response :missing
        assert_flash_error I18n.t(:error_test_case_not_found)
      end

      def test_update_with_missing_params
        test_case = test_cases(:test_cases_001)
        test_plan = test_plans(:test_plans_002)
        assert_no_difference("TestCase.count") do
          put :update, params: {
                project_id: projects(:projects_003).identifier,
                test_plan_id: test_plan.id,
                id: test_case.id,
                test_case: {
                  test_plan_id: test_plans(:test_plans_002).id,
                  name: "test",
                  user: 2
                }
              }
        end
        assert_response :unprocessable_entity
        assert_flash_error I18n.t(:error_update_failure)
      end
    end

    class Destroy < self
      def test_destroy
        assert_difference("TestCase.count", -1) do
          delete :destroy, params: {
                   project_id: projects(:projects_002).identifier,
                   test_plan_id: test_plans(:test_plans_002).id,
                   id: test_cases(:test_cases_001).id
                 }
        end
        assert_equal I18n.t(:notice_successful_delete), flash[:notice]
        assert_redirected_to project_test_plan_test_cases_path
      end

      def test_destroy_with_nonexistent_project
        assert_no_difference("TestCase.count") do
          delete :destroy, params: {
                   project_id: NONEXISTENT_PROJECT_ID,
                   test_plan_id: test_plans(:test_plans_002).id,
                   id: test_cases(:test_cases_001).id
                 }
        end
        assert_response :missing
        assert_flash_error I18n.t(:error_project_not_found)
      end

      def test_destroy_with_nonexistent_test_plan
        assert_no_difference("TestCase.count") do
          delete :destroy, params: {
                   project_id: projects(:projects_002).identifier,
                   test_plan_id: NONEXISTENT_TEST_PLAN_ID,
                   id: test_cases(:test_cases_001).id
                 }
        end
        assert_response :missing
        assert_flash_error I18n.t(:error_test_plan_not_found)
      end

      def test_destroy_with_nonexistent_test_case
        assert_no_difference("TestCase.count") do
          delete :destroy, params: {
                   project_id: projects(:projects_002).identifier,
                   test_plan_id: test_plans(:test_plans_002).id,
                   id: NONEXISTENT_TEST_CASE_ID
                 }
        end
        assert_response :missing
        assert_flash_error I18n.t(:error_test_case_not_found)
      end

      def test_destroy_dependent_test_case_executions
        assert_difference("TestCase.count", -1) do
          assert_difference("TestCaseExecution.count", -1) do
            delete :destroy, params: {
                     project_id: projects(:projects_002).identifier,
                     test_plan_id: test_plans(:test_plans_003).id,
                     id: test_cases(:test_cases_002).id
                   }
          end
        end
        assert_equal I18n.t(:notice_successful_delete), flash[:notice]
        assert_redirected_to project_test_plan_test_cases_path
      end
    end
  end
end
