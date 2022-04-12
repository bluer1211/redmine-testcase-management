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
      def setup
        login_with_permissions(projects(:projects_003), [:view_project, :view_issues])
      end

      def test_index
        get :index, params: {
              project_id: projects(:projects_003).identifier,
            }
        assert_response :success
        # match all test cases
        assert_equal test_cases(:test_cases_003, :test_cases_002, :test_cases_001).pluck(:id),
                     css_select("table#test_cases_list tbody tr td.id").map(&:text).map(&:to_i)
        columns = []
        assert_select "table#test_cases_list thead tr:first-child th" do |ths|
          ths.each do |th|
            columns << th.text
          end
        end
        assert_equal ['#',
                      I18n.t(:field_name),
                      I18n.t(:field_environment),
                      I18n.t(:field_user),
                      I18n.t(:field_latest_result),
                      I18n.t(:field_execution_date),
                      I18n.t(:field_scenario),
                      I18n.t(:field_expected)
                     ],
                     columns
        assert_select "div#content div.contextual > a:first-child" do |a|
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

      def test_breadcrumb_with_test_plan
        test_plan = test_plans(:test_plans_001)
        get :index, params: {
              project_id: projects(:projects_003).identifier,
              test_plan_id: test_plan.id,
            }
        assert_select "div#content h2.inline-flex" do |h2|
          assert_equal "#{I18n.t(:label_test_plans)} » ##{test_plan.id} #{test_plan.name} » #{I18n.t(:label_test_cases)}", h2.text
        end
      end

      def test_breadcrumb_without_test_plan
        get :index, params: {
              project_id: projects(:projects_003).identifier,
            }
        assert_select "div#content h2.inline-flex" do |h2|
          assert_equal "#{I18n.t(:label_test_cases)}", h2.text
        end
      end
    end

    class Filter < self
      def setup
        @project = projects(:projects_003)
        login_with_permissions(@project, [:view_project, :view_issues])
        @test_case = TestCase.create(name: "dummy",
                                     scenario: "dummy",
                                     expected: "dummy",
                                     environment: "dummy",
                                     project: @project,
                                     user: @user)
      end

      def teardown
        @test_case.destroy
      end

      def test_index_with_invalid_filter
        get :index, params: filter_params("user_id", "=", {})
        assert_flash_error I18n.t(:error_index_failure)
        assert_response :unprocessable_entity
      end

      def test_index_with_name_filter
        get :index, params: filter_params("name", "~",
                                          { "name": [@test_case.name] })
        assert_response :success
        assert_equal [@test_case.id],
                     css_select("table#test_cases_list tbody tr td.id").map(&:text).map(&:to_i)
      end

      def test_index_with_user_filter
        get :index, params: filter_params("user_id", "=", { "user_id": [@user.id] })
        assert_response :success
        assert_equal [@test_case.id],
                     css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_index_with_environment_filter
        get :index, params: filter_params("environment", "~",
                                          { "environment": [@test_case.environment] })
        assert_response :success
        assert_equal [@test_case.id],
                     css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_index_with_scenario_filter
        get :index, params: filter_params("scenario", "~",
                                          { "scenario": [@test_case.scenario] })
        assert_response :success
        assert_equal [@test_case.id],
                     css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_index_with_expected_filter
        get :index, params: filter_params("expected", "~",
                                          { "expected": [@test_case.expected] })
        assert_response :success
        assert_equal [@test_case.id],
                     css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_index_with_succeeded_result_filter
        get :index, params: filter_params("latest_result", "=",
                                          { "latest_result": [true] })
        assert_response :success
        # @test_case should not listed
        assert_equal [test_cases(:test_cases_002).id],
                     css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_index_with_failed_result_filter
        get :index, params: filter_params("latest_result", "=",
                                          { "latest_result": [false] })
        assert_response :success
        # @test_case is not associated test case execution
        assert_equal [test_cases(:test_cases_003).id],
                     css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_index_with_execution_date_filter
        ActiveRecord::Base.default_timezone = :utc
        test_case_execution = test_case_executions(:test_case_executions_003)
        get :index, params: filter_params("execution_date", "=",
                                          { "execution_date": [test_case_execution.execution_date.strftime("%F")] })
        assert_response :success
        # @test_case should not listed
        assert_equal [test_cases(:test_cases_003).id],
                     css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
      end

      private

      def filter_params(field, operation, values)
        filters = {
          project_id: @project.identifier,
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
        @test_case = TestCase.create(name: "dummy",
                                     scenario: "dummy",
                                     expected: "dummy",
                                     environment: "dummy",
                                     project: @project,
                                     user: @user)
        @order_params = {
          project_id: @project.identifier
        }
      end

      def teardown
        @test_case.destroy
      end

      def test_id_order_by_desc
        ids = test_cases(:test_cases_003, :test_cases_002, :test_cases_001).pluck(:id)
        ids.unshift(@test_case.id)
        get :index, params: @order_params
        assert_response :success
        assert_equal ids,
                     css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_id_order_by_asc
        ids = test_cases(:test_cases_001, :test_cases_002, :test_cases_003).pluck(:id)
        ids.push(@test_case.id)
        get :index, params: @order_params.merge({ sort: "id:asc" })
        assert_response :success
        assert_equal ids,
                     css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_name_order_by_desc
        ids = test_cases(:test_cases_003, :test_cases_002, :test_cases_001).pluck(:id)
        # test case ..., dummy
        ids.push(@test_case.id)
        get :index, params: @order_params.merge({ sort: "name:desc" })
        assert_response :success
        assert_equal ids,
                     css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_name_order_by_asc
        ids = test_cases(:test_cases_001, :test_cases_002, :test_cases_003).pluck(:id)
        # dummy, test case ...
        ids.unshift(@test_case.id)
        get :index, params: @order_params.merge({ sort: "name:asc" })
        assert_response :success
        assert_equal ids,
                     css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_user_order_by_desc
        test_cases(:test_cases_001).update(user: users(:users_001))
        test_cases(:test_cases_003).update(user: users(:users_003))
        ids = test_cases(:test_cases_003, :test_cases_002, :test_cases_001).pluck(:id)
        ids.unshift(@test_case.id)
        get :index, params: @order_params.merge({ sort: "user:desc" })
        assert_response :success
        # should be listed in @user, dlopper, jsmith, admin
        assert_equal ids,
                     css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_user_order_by_asc
        test_cases(:test_cases_001).update(user: users(:users_001))
        test_cases(:test_cases_003).update(user: users(:users_003))
        ids = test_cases(:test_cases_001, :test_cases_002, :test_cases_003).pluck(:id)
        ids.push(@test_case.id)
        get :index, params: @order_params.merge({ sort: "user:asc" })
        assert_response :success
        # should be listed in admin, jsmith, dlopper, @user
        assert_equal ids,
                     css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_scenario_order_by_desc
        ids = test_cases(:test_cases_003, :test_cases_002, :test_cases_001).pluck(:id)
        ids.push(@test_case.id)
        get :index, params: @order_params.merge({ sort: "scenario:desc" })
        assert_response :success
        assert_equal ids,
                     css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_scenario_order_by_asc
        ids = test_cases(:test_cases_001, :test_cases_002, :test_cases_003).pluck(:id)
        ids.unshift(@test_case.id)
        get :index, params: @order_params.merge({ sort: "scenario:asc" })
        assert_response :success
        assert_equal ids,
                     css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_expected_order_by_desc
        ids = test_cases(:test_cases_003, :test_cases_002, :test_cases_001).pluck(:id)
        ids.push(@test_case.id)
        get :index, params: @order_params.merge({ sort: "expected:desc" })
        assert_response :success
        assert_equal ids,
                     css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_expected_order_by_asc
        ids = test_cases(:test_cases_001, :test_cases_002, :test_cases_003).pluck(:id)
        ids.unshift(@test_case.id)
        get :index, params: @order_params.merge({ sort: "expected:asc" })
        assert_response :success
        assert_equal ids,
                     css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_result_order_by_desc
        ids = test_cases(:test_cases_001, :test_cases_002, :test_cases_003).pluck(:id)
        ids.unshift(@test_case.id)
        # should be listed in none (desc), true, false
        get :index, params: @order_params.merge({ sort: "latest_result:desc,id:desc" })
        assert_response :success
        assert_equal ids,
                     css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_result_order_by_asc
        ids = test_cases(:test_cases_003, :test_cases_002).pluck(:id)
        ids.push(@test_case.id)
        ids.push(test_cases(:test_cases_001).id)
        # should be listed in false, true, none (desc)
        get :index, params: @order_params.merge({ sort: "latest_result:asc, id:asc" })
        assert_response :success
        assert_equal ids,
                     css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
      end
    end

    class New < self
      def test_breadcrumb_with_test_plan
        test_plan = test_plans(:test_plans_001)
        get :new, params: {
              project_id: projects(:projects_002).identifier,
              test_plan_id: test_plan.id,
            }
        assert_select "div#content h2.inline-flex" do |h2|
          assert_equal "#{I18n.t(:label_test_plans)} » ##{test_plan.id} #{test_plan.name} » #{I18n.t(:label_test_case_new)}", h2.text
        end
      end

      def test_breadcrumb_without_test_plan
        get :new, params: {
              project_id: projects(:projects_002).identifier,
            }
        assert_select "div#content h2" do |h2|
          assert_equal "#{I18n.t(:label_test_cases)} » #{I18n.t(:label_test_case_new)}", h2.text
        end
      end
    end

    class Create < self
      def setup
        login_with_permissions(projects(:projects_001), [:view_project, :view_issues, :add_issues])
      end

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
        assert_response :missing
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
      def setup
        login_with_permissions(projects(:projects_002), [:view_project, :view_issues])
      end

      def test_show
        test_case = test_cases(:test_cases_002)
        get :show, params: {
              project_id: projects(:projects_002).identifier,
              id: test_case.id
            }
        assert_response :success
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

      def test_breadcrumb_with_test_plan
        test_plan = test_plans(:test_plans_001)
        test_case = test_cases(:test_cases_002)
        get :show, params: {
              project_id: projects(:projects_002).identifier,
              test_plan_id: test_plan.id,
              id: test_case.id,
            }
        assert_select "div#content h2.inline-flex" do |h2|
          assert_equal "#{I18n.t(:label_test_plans)} » ##{test_plan.id} #{test_plan.name} » \##{test_case.id} #{test_case.name}", h2.text
        end
      end

      def test_breadcrumb_without_test_plan
        test_case = test_cases(:test_cases_002)
        get :show, params: {
              project_id: projects(:projects_002).identifier,
              id: test_case.id,
            }
        assert_select "div#content h2.inline-flex" do |h2|
          assert_equal "#{I18n.t(:label_test_cases)} » \##{test_case.id} #{test_case.name}", h2.text
        end
      end
    end

    class Edit < self
      def setup
        login_with_permissions(projects(:projects_002), [:view_project, :view_issues, :edit_issues])
      end

      def test_edit
        test_case = test_cases(:test_cases_001)
        get :edit, params: {
              project_id: projects(:projects_002).identifier,
              id: test_case.id
            }
        assert_response :success
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

      def test_breadcrumb_with_test_plan
        test_plan = test_plans(:test_plans_001)
        test_case = test_cases(:test_cases_001)
        get :edit, params: {
              project_id: projects(:projects_002).identifier,
              test_plan_id: test_plan.id,
              id: test_case.id
            }
        assert_select "div#content h2.inline-flex" do |h2|
          assert_equal "#{I18n.t(:label_test_plans)} » ##{test_plan.id} #{test_plan.name} » #{I18n.t(:label_test_case_edit)} ##{test_case.id}", h2.text
        end
      end

      def test_breadcrumb_without_test_plan
        test_case = test_cases(:test_cases_001)
        get :edit, params: {
              project_id: projects(:projects_002).identifier,
              id: test_case.id
            }
        assert_select "div#content h2" do |h2|
          assert_equal "#{I18n.t(:label_test_cases)} » #{I18n.t(:label_test_case_edit)} ##{test_case.id}", h2.text
        end
      end
    end

    class Update < self
      def setup
        login_with_permissions(projects(:projects_002, :projects_003), [:view_project, :view_issues, :edit_issues])
      end

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
      def setup
        login_with_permissions(projects(:projects_003), [:view_project, :view_issues, :delete_issues])
      end

      def test_destroy
        assert_difference("TestCase.count", -1) do
          delete :destroy, params: {
                   project_id: projects(:projects_003).identifier,
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
                   project_id: projects(:projects_003).identifier,
                   id: NONEXISTENT_TEST_CASE_ID
                 }
        end
        assert_response :missing
        assert_flash_error I18n.t(:error_test_case_not_found)
      end

      def test_destroy_dependent_test_case_executions
        assert_difference("TestCaseExecution.count", -1) do
          assert_difference("TestCase.count", -1) do
            delete :destroy, params: {
                     project_id: projects(:projects_003).identifier,
                     id: test_cases(:test_cases_002).id
                   }
          end
        end
        assert_equal I18n.t(:notice_successful_delete), flash[:notice]
        assert_redirected_to project_test_cases_path
      end
    end

    class AutoComplete < self
      class Authorized < self
        def setup
          @project = projects(:projects_003)
          login_with_permissions(@project, [:view_project, :view_issues])
          @params = {
            project_id: @project.identifier
          }
        end

        def test_missing_test_plan
          get :auto_complete, params: @params.merge({term: "TEST"})
          assert_response :success
          assert_equal [],
                       JSON.parse(@response.body)
        end

        def test_nonexistent_test_plan
          get :auto_complete, params: @params.merge({term: "TEST", test_plan_id: NONEXISTENT_TEST_PLAN_ID})
          assert_equal [],
                       JSON.parse(@response.body)
        end

        def test_uppercase_name
          get :auto_complete, params: @params.merge({term: "TEST", test_plan_id: test_plans(:test_plans_002).id})
          assert_response :success
          expected = []
          test_cases(:test_cases_003, :test_cases_002).each do |test_case|
            expected << {
              "id" => test_case.id,
              "label" => "##{test_case.id} #{test_case.name}",
              "value" => test_case.id
            }
          end
          assert_equal expected,
                       JSON.parse(@response.body)
        end

        def test_lowercase_name
          get :auto_complete, params: @params.merge({term: "test", test_plan_id: test_plans(:test_plans_002).id})
          assert_response :success
          expected = []
          test_cases(:test_cases_003, :test_cases_002).each do |test_case|
            expected << {
              "id" => test_case.id,
              "label" => "##{test_case.id} #{test_case.name}",
              "value" => test_case.id
            }
          end
          assert_equal expected,
                       JSON.parse(@response.body)
        end

        def test_non_associated
          get :auto_complete, params: @params.merge({term: "test",
                                                     test_plan_id: test_plans(:test_plans_003).id})
          assert_response :success
          expected = []
          # non associated test_cases_001 should be listed
          test_case = test_cases(:test_cases_001)
          expected << {
            "id" => test_case.id,
            "label" => "##{test_case.id} #{test_case.name}",
            "value" => test_case.id
          }
          assert_equal expected,
                       JSON.parse(@response.body)
        end

      end

      class Unauthorized < self
        def setup
          @project = projects(:projects_003)
          @params = {
            project_id: @project.identifier
          }
        end

        def test_without_permission
          # No view_issues
          generate_user_with_permissions(@project, [:view_project])
          @request.session[:user_id] = @user.id
          get :auto_complete, params: @params.merge({term: "test",
                                                     test_plan_id: test_plans(:test_plans_003).id})
          assert_response :success
          assert_equal [],
                       JSON.parse(@response.body)
        end
      end
    end
  end

  class AssociatedWithTestPlan < self
    class Index < self
      def setup
        login_with_permissions(projects(:projects_003), [:view_project, :view_issues])
      end

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
                      I18n.t(:field_latest_result),
                      I18n.t(:field_execution_date),
                      I18n.t(:field_scenario),
                      I18n.t(:field_expected)
                     ],
                     columns
        assert_select "div#content div.contextual > a:first-child" do |a|
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

        def test_index_with_result_filter
          get :index, params: filter_params("latest_result", "=",
                                            { "latest_result": [true] })
          assert_response :success
          # test_cases_003 must be ignored
          assert_equal [test_cases(:test_cases_002).id],
                       css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
        end

        def test_index_with_result_filter
          get :index, params: filter_params("latest_result", "=",
                                            { "latest_result": [false] })
          assert_response :success
          # test_cases_002 must be ignored
          assert_equal [test_cases(:test_cases_003).id],
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

        def test_result_order_by_desc
          ids = test_cases(:test_cases_002, :test_cases_003).pluck(:id)
          get :index, params: @order_params.merge({ sort: "latest_result:desc" })
          assert_response :success
          assert_equal ids,
                       css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
        end

        def test_result_order_by_asc
          ids = test_cases(:test_cases_003, :test_cases_002).pluck(:id)
          get :index, params: @order_params.merge({ sort: "latest_result:asc" })
          assert_response :success
          assert_equal ids,
                       css_select("table#test_cases_list tr td.id").map(&:text).map(&:to_i)
        end
      end
    end

    class Create < self
      def setup
        login_with_permissions(projects(:projects_001), [:view_project, :view_issues, :add_issues])
      end

      def test_create_with_test_plan
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
        assert_redirected_to project_test_plan_path(id: test_plans(:test_plans_001).id)
      end

      def test_create_without_test_plan
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
        assert_redirected_to project_test_case_path(id: TestCase.last.id)
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
        assert_response :missing
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
        assert_response :missing
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
      def setup
        login_with_permissions(projects(:projects_002), [:view_project, :view_issues])
      end

      def test_show_without_execution
        test_case = test_cases(:test_cases_001)
        test_plan = test_plans(:test_plans_003)
        test_plan.test_cases << test_case
        test_plan.save!
        get :show, params: {
              project_id: projects(:projects_002).identifier,
              test_plan_id: test_plan.id,
              id: test_case.id
            }
        assert_response :success
        assert_select "div#content h2.inline-flex" do |h2|
          assert_equal "#{I18n.t(:label_test_plans)} » ##{test_plan.id} #{test_plan.name} » \##{test_case.id} #{test_case.name}", h2.text
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
        assert_select "div#test_case_execution_tree tbody tr", 0
      end

      def test_show_with_execution
        test_case = test_cases(:test_cases_002)
        test_plan = test_plans(:test_plans_003)
        get :show, params: {
              project_id: projects(:projects_002).identifier,
              test_plan_id: test_plan.id,
              id: test_case.id
            }
        assert_response :success
        assert_select "div#test_case_execution_tree div.contextual a:first-child", 0
        assert_select "div#test_case_execution_tree tbody tr", 1
      end

      def test_show_without_test_plan
        test_case = test_cases(:test_cases_002)
        get :show, params: {
              project_id: projects(:projects_002).identifier,
              id: test_case.id
            }
        assert_response :success
        assert_select "div#test_case_execution_tree div.contextual a:first-child", 0
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
      def setup
        login_with_permissions(projects(:projects_002), [:view_project, :view_issues, :edit_issues])
      end

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
          assert_equal "#{I18n.t(:label_test_plans)} » ##{test_plan.id} #{test_plan.name} » #{I18n.t(:label_test_case_edit)} ##{test_case.id}", h2.text
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
      def setup
        login_with_permissions(projects(:projects_002, :projects_003), [:view_project, :view_issues, :edit_issues])
      end

      def test_update_with_test_plan
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
        assert_redirected_to project_test_plan_path(:id => test_plan.id)
      end

      def test_update_without_test_plan
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
      def setup
        login_with_permissions(projects(:projects_003), [:view_project, :view_issues, :delete_issues])
      end

      def test_destroy_with_test_plan
        assert_difference("TestCase.count", -1) do
          delete :destroy, params: {
                   project_id: projects(:projects_003).identifier,
                   test_plan_id: test_plans(:test_plans_002).id,
                   id: test_cases(:test_cases_001).id
                 }
        end
        assert_equal I18n.t(:notice_successful_delete), flash[:notice]
        assert_redirected_to project_test_plan_path(id: test_plans(:test_plans_002).id)
      end

      def test_destroy_without_test_plan
        assert_difference("TestCase.count", -1) do
          delete :destroy, params: {
                   project_id: projects(:projects_003).identifier,
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
                   project_id: projects(:projects_003).identifier,
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
                   project_id: projects(:projects_003).identifier,
                   test_plan_id: test_plans(:test_plans_002).id,
                   id: NONEXISTENT_TEST_CASE_ID
                 }
        end
        assert_response :missing
        assert_flash_error I18n.t(:error_test_case_not_found)
      end

      def test_destroy_dependent_test_case_executions
        assert_difference("TestCaseExecution.count", -1) do
          assert_difference("TestCase.count", -1) do
            delete :destroy, params: {
                     project_id: projects(:projects_003).identifier,
                     test_plan_id: test_plans(:test_plans_003).id,
                     id: test_cases(:test_cases_002).id
                   }
          end
        end
        assert_equal I18n.t(:notice_successful_delete), flash[:notice]
        assert_redirected_to project_test_plan_path(id: test_plans(:test_plans_003).id)
      end
    end
  end

  class ViewWithoutPermissions < self
    def setup
      login_with_permissions(projects(:projects_001, :projects_002, :projects_003), [:view_project])
    end

    def test_index
      get :index, params: {
            project_id: projects(:projects_003).identifier,
          }
      assert_response :success
      assert_select "tbody tr", 0
    end

    def test_index_with_test_plan
      get :index, params: {
            project_id: projects(:projects_003).identifier,
            test_plan_id: test_plans(:test_plans_003).id
          }
      assert_response :missing
    end

    def test_create
      assert_no_difference("TestCase.count") do
        post :create, params: {
               project_id: projects(:projects_001).identifier,
               test_case: {
                 name: "test", scenario: "dummy", expected: "dummy", environment: "dummy",
                 user: 2
               }
             }
      end
      assert_response :forbidden
    end

    def test_create_with_test_plan
      assert_no_difference("TestCase.count") do
        post :create, params: {
               project_id: projects(:projects_001).identifier,
               test_plan_id: test_plans(:test_plans_001).id,
               test_case: {
                 name: "test", scenario: "dummy", expected: "dummy", environment: "dummy",
                 user: 2
               }
             }
      end
      assert_response :missing
    end

    def test_show
      test_case = test_cases(:test_cases_002)
      get :show, params: {
            project_id: projects(:projects_002).identifier,
            id: test_case.id
          }
      assert_response :missing
    end

    def test_show_with_test_plan
      test_case = test_cases(:test_cases_002)
      test_plan = test_plans(:test_plans_003)
      get :show, params: {
            project_id: projects(:projects_002).identifier,
            test_plan_id: test_plan.id,
            id: test_case.id
          }
      assert_response :missing
    end

    def test_edit
      test_case = test_cases(:test_cases_001)
      get :edit, params: {
            project_id: projects(:projects_002).identifier,
            id: test_case.id
          }
      assert_response :missing
    end

    def test_edit_with_test_plan
      test_plan = test_plans(:test_plans_002)
      test_case = test_cases(:test_cases_001)
      get :edit, params: {
            project_id: projects(:projects_002).identifier,
            test_plan_id: test_plan.id,
            id: test_case.id
          }
      assert_response :missing
    end

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
      assert_response :missing
    end

    def test_update_with_test_plan
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
      assert_response :missing
    end

    def test_destroy
      assert_no_difference("TestCase.count", -1) do
        delete :destroy, params: {
                 project_id: projects(:projects_003).identifier,
                 id: test_cases(:test_cases_001).id
               }
      end
      assert_response :missing
    end

    def test_destroy_with_test_plan
      assert_no_difference("TestCase.count", -1) do
        delete :destroy, params: {
                 project_id: projects(:projects_003).identifier,
                 test_plan_id: test_plans(:test_plans_002).id,
                 id: test_cases(:test_cases_001).id
               }
      end
      assert_response :missing
    end
  end

  class ModifyWithoutPermissions < self
    def setup
      login_with_permissions(projects(:projects_001, :projects_002, :projects_003), [:view_project, :view_issues])
    end

    def test_create
      assert_no_difference("TestCase.count") do
        post :create, params: {
               project_id: projects(:projects_001).identifier,
               test_case: {
                 name: "test", scenario: "dummy", expected: "dummy", environment: "dummy",
                 user: 2
               }
             }
      end
      assert_response :forbidden
    end

    def test_create_with_test_plan
      assert_no_difference("TestCase.count") do
        post :create, params: {
               project_id: projects(:projects_001).identifier,
               test_plan_id: test_plans(:test_plans_001).id,
               test_case: {
                 name: "test", scenario: "dummy", expected: "dummy", environment: "dummy",
                 user: 2
               }
             }
      end
      assert_response :forbidden
    end

    def test_edit
      test_case = test_cases(:test_cases_001)
      get :edit, params: {
            project_id: projects(:projects_002).identifier,
            id: test_case.id
          }
      assert_response :forbidden
    end

    def test_edit_with_test_plan
      test_plan = test_plans(:test_plans_002)
      test_case = test_cases(:test_cases_001)
      get :edit, params: {
            project_id: projects(:projects_002).identifier,
            test_plan_id: test_plan.id,
            id: test_case.id
          }
      assert_response :forbidden
    end

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
      assert_response :forbidden
    end

    def test_update_with_test_plan
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
      assert_response :forbidden
    end

    def test_destroy
      assert_no_difference("TestCase.count", -1) do
        delete :destroy, params: {
                 project_id: projects(:projects_003).identifier,
                 id: test_cases(:test_cases_001).id
               }
      end
      assert_response :forbidden
    end

    def test_destroy_with_test_plan
      assert_no_difference("TestCase.count", -1) do
        delete :destroy, params: {
                 project_id: projects(:projects_003).identifier,
                 test_plan_id: test_plans(:test_plans_002).id,
                 id: test_cases(:test_cases_001).id
               }
      end
      assert_response :forbidden
    end
  end

  class Statistics < self
    class SingleUser < self
      def setup
        @test_case = test_cases(:test_cases_004)
        @project = @test_case.project
        @test_plan = @test_case.test_plan
        @test_case_execution = @test_case.test_case_executions.first
        @params = { project_id: @project.identifier }
        @user = users(:users_002)
        @closed_issue = issues(:issues_008)
        @closed_status = issue_statuses(:issue_statuses_005)
      end

      def test_statistics
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        expected = {
          id: [@test_plan.user.id],
          user: [@test_plan.user.name],
          test_cases: [@test_plan.test_cases.size],
          assigned_rate: [100],
          count_not_executed: [0],
          count_succeeded: [1],
          count_failed: [0],
          progress_rate: [100],
          detected_bug: [0],
          remained_bug: [0],
          fixed_rate: [0],
        }
        assert_equal expected, actual_statistics
      end

      def test_no_statistics
        # no test case, no statistics
        TestPlan.find(test_plans(:test_plans_005).id).destroy
        @project = projects(:projects_001)
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        assert_select "p.nodata"
      end

      def test_ignore_closed_test_plan
        TestPlan.find(test_plans(:test_plans_003).id).update(issue_status: @closed_status)
        @project = projects(:projects_003)
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        # under test plan 3 should be ignored
        @user = users(:users_002)
        expected = {
          id: [@user.id],
          user: [@user.name],
          test_cases: [1],
          assigned_rate: [100],
          count_not_executed: [1],
          count_succeeded: [0],
          count_failed: [0],
          progress_rate: [0],
          detected_bug: [0],
          remained_bug: [0],
          fixed_rate: [0],
        }
        assert_equal expected, actual_statistics
      end

      def test_count_not_executed
        TestCaseExecution.find(test_case_executions(:test_case_executions_004).id).destroy
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        assert_equal [1], css_select("table#statistics tr td.count_not_executed").map(&:text).map(&:to_i)
      end

      def test_no_count_not_executed
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        assert_equal [0], css_select("table#statistics tr td.count_not_executed").map(&:text).map(&:to_i)
      end

      def test_count_succeeded
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        assert_equal [1], css_select("table#statistics tr td.count_succeeded").map(&:text).map(&:to_i)
      end

      def test_no_count_succeeded
        TestCaseExecution.create(project: @project,
                                 test_plan: @test_plan,
                                 test_case: @test_case,
                                 user: @user,
                                 result: false,
                                 execution_date: Time.now.strftime("%F"),
                                 comment: "dummy")
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        # latest failed test case execution should be counted
        assert_equal [0], css_select("table#statistics tr td.count_succeeded").map(&:text).map(&:to_i)
      end

      def test_count_failed
        TestCaseExecution.create(project: @project,
                                 test_plan: @test_plan,
                                 test_case: @test_case,
                                 user: @user,
                                 result: false,
                                 execution_date: Time.now.strftime("%F"),
                                 comment: "dummy")
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        assert_equal [1], css_select("table#statistics tr td.count_failed").map(&:text).map(&:to_i)
      end

      def test_no_count_failed
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        assert_equal [0], css_select("table#statistics tr td.count_failed").map(&:text).map(&:to_i)
      end

      def test_no_progress_rate
        TestCaseExecution.find(@test_case_execution.id).destroy
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        assert_equal [0], css_select("table#statistics tr td.progress_rate").map(&:text).map(&:to_i)
      end

      def test_progress_rate_with_succeeded_only
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        # true => 1/1
        assert_equal [100], css_select("table#statistics tr td.progress_rate").map(&:text).map(&:to_i)
      end

      def test_progress_rate_with_failed_only
        add_test_case_with_test_case_execution({ result: false })
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        # false = 1/1
        assert_equal [100], css_select("table#statistics tr td.progress_rate").map(&:text).map(&:to_i)
      end

      def test_progress_rate_with_mixed_result
        add_test_case_without_test_case_execution
        add_test_case_with_test_case_execution({ result: false })
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        # true, none, false => 2/3
        assert_equal [67], css_select("table#statistics tr td.progress_rate").map(&:text).map(&:to_i)
      end

      def test_no_detected_bug
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        assert_equal [0], css_select("table#statistics tr td.detected_bug").map(&:text).map(&:to_i)
      end

      def test_detected_bug
        @test_case_execution.update(issue: issues(:issues_001))
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        assert_equal [1], css_select("table#statistics tr td.detected_bug").map(&:text).map(&:to_i)
      end

      def test_no_remained_bug
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        assert_equal [0], css_select("table#statistics tr td.remained_bug").map(&:text).map(&:to_i)
      end

      def test_remained_bug
        @project = projects(:projects_001)
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        # Even though same issue is assigned to multiple test case (and as a execution), they are counted
        assert_equal [2], css_select("table#statistics tr td.detected_bug").map(&:text).map(&:to_i)
      end

      def test_remained_bug
        @project = projects(:projects_001)
        @test_case_execution = test_case_executions(:test_case_executions_007)
        # prepare closed issue
        @test_case_execution.update(issue: issues(:issues_008))
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        # associated issues 2 - 1 (closed)
        assert_equal [1], css_select("table#statistics tr td.remained_bug").map(&:text).map(&:to_i)
      end

      def test_no_fixed_rate
        TestCaseExecution.find(@test_case_execution.id).destroy
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        # detected_bug is 0, so it can't be calculated
        assert_equal ['-'], css_select("table#statistics tr td.fixed_rate").map(&:text).map(&:strip)
      end

      def test_fixed_rate
        @project = projects(:projects_001)
        @test_case_execution = test_case_executions(:test_case_executions_007)
        # prepare closed issue
        @test_case_execution.update(issue: @closed_issue)
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        # associated issues 1/2
        assert_equal [50], css_select("table#statistics tr td.fixed_rate").map(&:text).map(&:to_i)
      end

      def test_fixed_rate_some
        @project = projects(:projects_001)
        test_case_executions(:test_case_executions_005,
                             :test_case_executions_006).each do |test_case_execution|
          # prepare closed issue
          test_case_execution.update(issue: @closed_issue)
        end
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        # associated issues 2/3
        assert_equal [67], css_select("table#statistics tr td.fixed_rate").map(&:text).map(&:to_i)
      end

      def test_fixed_rate_all
        @project = projects(:projects_001)
        test_case_executions(:test_case_executions_005,
                             :test_case_executions_006,
                             :test_case_executions_007).each do |test_case_execution|
          # prepare closed issue
          test_case_execution.update(issue: @closed_issue)
        end
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        # associated issues 3/3
        assert_equal [100], css_select("table#statistics tr td.fixed_rate").map(&:text).map(&:to_i)
      end
    end

    class MultipleUser < self
      def setup
        @project = projects(:projects_001)
        @params = { project_id: @project.identifier }
        @closed_issue = issues(:issues_008)
        @open_issue = issues(:issues_002)
        @closed_status = issue_statuses(:issue_statuses_005)
        @jsmith = users(:users_002)
        @dlopper = users(:users_003)
        TestPlan.find(test_plans(:test_plans_001).id).update(user: @dlopper)
        @test_plan = test_plans(:test_plans_001)
        @user = @dlopper
      end

      def test_statistics
        add_test_case_with_test_case_execution(options={ result: false, issue: nil })
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        # In this case, order was determined by remained_bug
        expected = {
          id: [@jsmith.id, @dlopper.id],
          user: [@jsmith.name, @dlopper.name],
          test_cases: [3, 1],
          assigned_rate: [75, 25],
          count_not_executed: [0, 0],
          count_succeeded: [2, 0],
          count_failed: [1, 1],
          progress_rate: [100, 100],
          detected_bug: [2, 0],
          remained_bug: [2, 0],
          fixed_rate: [0, 0],
        }
        assert_equal expected, actual_statistics
      end

      def test_no_statistics
        # no test case, no statistics
        TestPlan.find(test_plans(:test_plans_005).id).destroy
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        assert_select "p.nodata"
      end

      def test_count_not_executed
        n = 3
        n.times { add_test_case_without_test_case_execution }
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        assert_equal [n, 0], css_select("table#statistics tr td.count_not_executed").map(&:text).map(&:to_i)
      end

      def test_no_count_not_executed
        n = 3
        n.times { add_test_case_with_test_case_execution(options={ result: false, issue: nil }) }
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        assert_equal [0, 0], css_select("table#statistics tr td.count_not_executed").map(&:text).map(&:to_i)
      end

      def test_count_succeeded
        n = 3
        n.times { add_test_case_with_test_case_execution(options={ result: true, issue: nil }) }
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        # In this case, order was determined by failed count
        assert_equal [2, 3], css_select("table#statistics tr td.count_succeeded").map(&:text).map(&:to_i)
      end

      def test_no_count_succeeded
        test_case = add_test_case_with_test_case_execution(options={ result: true, issue: nil })
        add_test_case_execution_for(test_case, { result: false })
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        # latest failed test case execution should be counted
        assert_equal [2, 1], css_select("table#statistics tr td.count_succeeded").map(&:text).map(&:to_i)
      end

      def test_count_failed
        n = 3
        n.times { add_test_case_with_test_case_execution(options={ result: false, issue: nil }) }
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        assert_equal [n, 1], css_select("table#statistics tr td.count_failed").map(&:text).map(&:to_i)
      end

      def test_no_count_failed
        n = 3
        n.times { add_test_case_with_test_case_execution(options={ result: true, issue: nil }) }
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        assert_equal [1, 0], css_select("table#statistics tr td.count_failed").map(&:text).map(&:to_i)
      end

      def test_no_progress_rate
        add_test_case_without_test_case_execution
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        assert_equal [0, 100], css_select("table#statistics tr td.progress_rate").map(&:text).map(&:to_i)
      end

      def test_progress_rate_with_succeeded_only
        n = 3
        n.times { add_test_case_with_test_case_execution(options={ result: true, issue: nil }) }
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        # true, true, true => 3/3
        assert_equal [100, 100], css_select("table#statistics tr td.progress_rate").map(&:text).map(&:to_i)
      end

      def test_progress_rate_with_failed_only
        n = 3
        n.times { add_test_case_with_test_case_execution(options={ result: false, issue: nil }) }
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        # false, false, false = 3/3
        assert_equal [100, 100], css_select("table#statistics tr td.progress_rate").map(&:text).map(&:to_i)
      end

      def test_progress_rate_with_mixed_result
        add_test_case_without_test_case_execution
        add_test_case_with_test_case_execution({ result: false })
        add_test_case_with_test_case_execution({ result: true })
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        # true, none, false => 2/3
        assert_equal [67, 100], css_select("table#statistics tr td.progress_rate").map(&:text).map(&:to_i)
      end

      def test_no_detected_bug
        add_test_case_without_test_case_execution
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        assert_equal [0, 2], css_select("table#statistics tr td.detected_bug").map(&:text).map(&:to_i)
      end

      def test_detected_bug
        add_test_case_with_test_case_execution({ result: false, issue: issues(:issues_001) })
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        assert_equal [2, 1], css_select("table#statistics tr td.detected_bug").map(&:text).map(&:to_i)
      end

      def test_no_remained_bug
        add_test_case_with_test_case_execution({ result: false })
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        assert_equal [2, 0], css_select("table#statistics tr td.remained_bug").map(&:text).map(&:to_i)
      end

      def test_remained_bug
        add_test_case_with_test_case_execution({ result: false, issue: @open_issue })
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        # Even though same issue is assigned to multiple test case (and as a execution), they are counted
        assert_equal [1, 2], css_select("table#statistics tr td.detected_bug").map(&:text).map(&:to_i)
      end

      def test_remained_bug
        add_test_case_with_test_case_execution({ result: false, issue: @closed_issue })
        add_test_case_with_test_case_execution({ result: false, issue: @open_issue })
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        # associated issues 2 - 1 (closed)
        assert_equal [1, 2], css_select("table#statistics tr td.remained_bug").map(&:text).map(&:to_i)
      end

      def test_no_fixed_rate
        add_test_case_without_test_case_execution
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        # detected_bug is 0, so it can't be calculated
        assert_equal ['-', '0'], css_select("table#statistics tr td.fixed_rate").map(&:text).map(&:strip)
      end

      def test_fixed_rate
        add_test_case_with_test_case_execution({ result: false, issue: @closed_issue })
        add_test_case_with_test_case_execution({ result: false, issue: @open_issue })
        add_test_case_with_test_case_execution({ result: false, issue: @closed_issue })
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: @params
        assert_response :success
        # associated issues 2/3
        assert_equal [67, 0], css_select("table#statistics tr td.fixed_rate").map(&:text).map(&:to_i)
      end

      def test_fixed_rate_all
        n = 3
        n.times { add_test_case_with_test_case_execution({ result: false, issue: @closed_issue }) }
        login_with_permissions(@project, [:view_project, :view_issues])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        # associated issues 3/3
        assert_equal [100, 0], css_select("table#statistics tr td.fixed_rate").map(&:text).map(&:to_i)
      end
    end

    private

    def add_test_case_with_test_case_execution(options={ result: true, issue: nil })
      test_case = add_test_case_without_test_case_execution
      TestCaseExecution.create(project: @project,
                               test_plan: @test_plan,
                               test_case: test_case,
                               user: @user,
                               result: options[:result],
                               issue: options[:issue],
                               execution_date: Time.now.strftime("%F"),
                               comment: "dummy")
      test_case
    end

    def add_test_case_without_test_case_execution
      test_case = TestCase.create(name: "dummy",
                                  scenario: "dummy",
                                  expected: "dummy",
                                  environment: "dummy",
                                  project: @project,
                                  user: @user)
      TestCaseTestPlan.create(test_plan: @test_plan,
                              test_case: test_case)
      test_case
    end

    def add_test_case_execution_for(test_case, options={ result: true, issue: nil })
      TestCaseExecution.create(project: @project,
                               test_plan: @test_plan,
                               test_case: test_case,
                               user: @user,
                               result: options[:result],
                               issue: options[:issue],
                               execution_date: Time.now.strftime("%F"),
                               comment: "dummy")
    end

    def actual_statistics
      data = {}
      %w(id test_cases count_not_executed count_succeeded count_failed
         assigned_rate progress_rate detected_bug remained_bug fixed_rate).each do |klass|
        data[klass.intern] = css_select("table#statistics tr td.#{klass}").map(&:text).map(&:to_i)
      end
      %w(user).each do |klass|
        data[klass.intern] = css_select("table#statistics tr td.#{klass}").map(&:text)
      end
      data
    end
  end

end
