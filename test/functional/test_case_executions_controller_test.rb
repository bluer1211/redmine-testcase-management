require File.expand_path('../../test_helper', __FILE__)

class TestCaseExecutionsControllerTest < ActionController::TestCase
  fixtures :projects, :users, :issues, :issue_statuses, :roles, :members, :member_roles,
           :groups_users, :trackers, :projects_trackers, :enabled_modules
  fixtures :test_plans, :test_cases, :test_case_executions, :test_case_test_plans

  include ApplicationsHelper

  NONEXISTENT_PROJECT_ID = 404
  NONEXISTENT_TEST_PLAN_ID = 404
  NONEXISTENT_TEST_CASE_ID = 404
  NONEXISTENT_TEST_CASE_EXECUTION_ID = 404

  class Index < self
    def setup
      @project = projects(:projects_003)
      login_with_permissions(@project, [:view_project, :view_issues])
    end

    def test_index
      get :index, params: {
            project_id: @project.identifier,
            test_plan_id: test_plans(:test_plans_003).id,
            test_case_id: test_cases(:test_cases_002).id,
            c: ["result", "user", "execution_date", "comment", "issue"]
          }
      assert_response :success
      assert_select "table#test_case_executions_list tbody tr", 1
      executions = []
      assert_select "table#test_case_executions_list tbody tr td:first-child" do |tds|
        tds.each do |td|
          executions << td.text.to_i
        end
      end
      assert_equal [test_case_executions(:test_case_executions_001).id], executions
      columns = []
      assert_select "table#test_case_executions_list thead tr:first-child th" do |ths|
        ths.each do |th|
          columns << th.text
        end
      end
      assert_equal ['#',
                    I18n.t(:field_result),
                    I18n.t(:field_user),
                    I18n.t(:field_execution_date),
                    I18n.t(:field_comment),
                    I18n.t(:field_issue),
                   ],
                   columns
      assert_contextual_link(I18n.t(:label_test_case_execution_new),
                             new_project_test_plan_test_case_test_case_execution_path)
    end

    def test_index_with_nonexistent_project
      get :index, params: {
            project_id: NONEXISTENT_PROJECT_ID,
            test_plan_id: test_plans(:test_plans_003).id,
            test_case_id: test_cases(:test_cases_002).id
          }
      assert_response :missing
      assert_flash_error I18n.t(:error_project_not_found)
      assert_back_to_lists_link(projects_path)
    end

    def test_index_with_nonexistent_test_plan
      project = projects(:projects_002)
      get :index, params: {
            project_id: project.identifier,
            test_plan_id: NONEXISTENT_TEST_PLAN_ID,
            test_case_id: test_cases(:test_cases_002).id
          }
      assert_response :missing
      assert_flash_error I18n.t(:error_test_plan_not_found)
      assert_back_to_lists_link(project_test_plans_path)
    end

    def test_index_with_nonexistent_test_case
      project = projects(:projects_002)
      get :index, params: {
            project_id: project.identifier,
            test_plan_id: test_plans(:test_plans_003).id,
            test_case_id: NONEXISTENT_TEST_CASE_ID
          }
      assert_response :missing
      assert_flash_error I18n.t(:error_test_case_not_found)
      assert_back_to_lists_link(project_test_plan_test_cases_path)
    end

    def test_breadcrumb
      get :index, params: {
            project_id: projects(:projects_002).identifier,
          }
      assert_select "div#content h2" do |h2|
        assert_equal "#{I18n.t(:label_test_case_executions)}", h2.text
      end
    end

    def test_breadcrumb_with_test_plan
      test_plan = test_plans(:test_plans_001)
      get :index, params: {
            project_id: projects(:projects_002).identifier,
            test_plan_id: test_plan.id,
          }
      assert_select "div#content h2.inline-flex" do |h2|
        assert_equal "#{I18n.t(:label_test_plans)} » ##{test_plan.id} #{test_plan.name} » #{I18n.t(:label_test_case_executions)}", h2.text
      end
    end

    def test_breadcrumb_with_test_case
      test_case = test_cases(:test_cases_001)
      get :index, params: {
            project_id: projects(:projects_002).identifier,
            test_case_id: test_case.id,
          }
      assert_select "div#content h2.inline-flex" do |h2|
        assert_equal "#{I18n.t(:label_test_cases)} » ##{test_case.id} #{test_case.name} » #{I18n.t(:label_test_case_executions)}", h2.text
      end
    end

    def test_breadcrumb_with_test_plan_and_test_case
      test_plan = test_plans(:test_plans_001)
      test_case = test_cases(:test_cases_001)
      get :index, params: {
            project_id: projects(:projects_002).identifier,
            test_plan_id: test_plan.id,
            test_case_id: test_case.id,
          }
      assert_select "div#content h2.inline-flex" do |h2|
        assert_equal "#{I18n.t(:label_test_plans)} » ##{test_plan.id} #{test_plan.name} » #{I18n.t(:label_test_cases)} ##{test_case.id} #{test_case.name} » #{I18n.t(:label_test_case_executions)}", h2.text
      end
    end

    class Filter < self
      class Invalid < self
        def test_index_with_invalid_filter
          get :index, params: {
                project_id: @project.identifier,
                test_plan_id: test_plans(:test_plans_003),
                test_case_id: test_cases(:test_cases_001),
                set_filter: 1,
                f: ['user_id'],
                op: {
                  'user_id' => "=",
                },
                v: {
                },
              }
          assert_flash_error I18n.t(:error_index_failure)
          assert_response :unprocessable_entity
        end
      end

      class Result < self
        def test_index_with_result_filter
          get :index, params: {
                project_id: @project.identifier,
                test_plan_id: test_plans(:test_plans_003),
                test_case_id: test_cases(:test_cases_003),
                set_filter: 1,
                f: ['result'],
                op: {
                  'result' => '='
                },
                v: {
                  'result': ['1'] # Works for SQLite3
                },
                c: ["result", "user", "execution_date", "comment", "issue"]
              }
          assert_response :success
          # test_case_executions_003(result=false) must be ignored
          assert_equal [test_case_executions(:test_case_executions_002).id],
                       css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
        end
      end

      class User < self
        def test_index_with_user_filter
          get :index, params: {
                project_id: @project.identifier,
                test_plan_id: test_plans(:test_plans_003),
                test_case_id: test_cases(:test_cases_003),
                set_filter: 1,
                f: ['user_id'],
                op: {
                  'user_id' => '='
                },
                v: {
                  'user_id': [users(:users_001).id]
                },
                c: ["result", "user", "execution_date", "comment", "issue"]
              }
          assert_response :success
          # test_case_executions_003 (users_002(id=2)) must be ignored
          assert_equal [test_case_executions(:test_case_executions_002).id],
                       css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
        end
      end

      class Issue < self
        def test_index_with_issue_filter
          get :index, params: {
                project_id: @project.identifier,
                test_plan_id: test_plans(:test_plans_003),
                test_case_id: test_cases(:test_cases_003),
                set_filter: 1,
                f: ['issue_id'],
                op: {
                  'issue_id' => '='
                },
                v: {
                  'issue_id': [issues(:issues_001).id]
                },
                c: ["result", "user", "execution_date", "comment", "issue"]
              }
          assert_response :success
          # test_case_executions_002 (empty issue) must be ignored
          assert_equal [test_case_executions(:test_case_executions_003).id],
                       css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
        end
      end

      class ExecutionDate < self
        def test_index_with_execution_date_filter
          ActiveRecord::Base.default_timezone = :utc
          test_case_execution = test_case_executions(:test_case_executions_003)
          get :index, params: {
                project_id: @project.identifier,
                test_plan_id: test_plans(:test_plans_003),
                test_case_id: test_cases(:test_cases_003),
                set_filter: 1,
                f: ['execution_date'],
                op: {
                  'execution_date' => '='
                },
                v: {
                  'execution_date': [test_case_execution.execution_date.strftime("%F")]
                },
                c: ["result", "user", "execution_date", "comment", "issue"]
              }
          assert_response :success
          # test_case_executions_002 must be ignored
          assert_equal [test_case_execution.id],
                       css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
        end
      end

      class Scenario < self
        def test_index_with_scenario_contains_filter
          test_case_execution = test_case_executions(:test_case_executions_001)
          get :index, params: filter_params(@project.identifier, "scenario", "~",
                                            {
                                              'scenario': [test_cases(:test_cases_002).scenario]
                                            },
                                            ["result", "user", "execution_date", "comment", "issue", "scenario"])
          assert_response :success
          # test_case_executions_001 must be ignored
          assert_equal [test_case_execution.id],
                       css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
        end

        def test_index_with_scenario_not_contains_filter
          test_case_execution = test_case_executions(:test_case_executions_001)
          get :index, params: filter_params(@project.identifier, "scenario", "!~",
                                            {
                                              'scenario': [test_cases(:test_cases_002).scenario]
                                            },
                                            ["result", "user", "execution_date", "comment", "issue", "scenario"])
          assert_response :success
          # test_case_executions_002,003 must be ignored
          assert_equal [test_case_executions(:test_case_executions_003).id,
                        test_case_executions(:test_case_executions_002).id],
                       css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
        end

        def test_index_with_scenario_starts_with_filter
          test_case_execution = test_case_executions(:test_case_executions_001)
          get :index, params: filter_params(@project.identifier, "scenario", "^",
                                            {
                                              'scenario': ["Scenario"]
                                            },
                                            ["result", "user", "execution_date", "comment", "issue", "scenario"])
          assert_response :success
          assert_equal [test_case_executions(:test_case_executions_003).id,
                        test_case_executions(:test_case_executions_002).id,
                        test_case_executions(:test_case_executions_001).id],
                       css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
        end

        def test_index_with_scenario_ends_with_filter
          test_case_execution = test_case_executions(:test_case_executions_001)
          get :index, params: filter_params(@project.identifier, "scenario", "$",
                                            {
                                              'scenario': ["2"]
                                            },
                                            ["result", "user", "execution_date", "comment", "issue", "scenario"])
          assert_response :success
          # test_case_executions_002,003 must be ignored
          assert_equal [test_case_execution.id],
                       css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
        end
      end

      class Expected < self
        def test_index_with_expected_contains_filter
          test_case_execution = test_case_executions(:test_case_executions_001)
          get :index, params: filter_params(@project.identifier, "expected", "~",
                                            {
                                              'expected': [test_cases(:test_cases_002).expected]
                                            },
                                            ["result", "user", "execution_date", "comment", "issue", "expected"])
          assert_response :success
          # test_case_executions_001 must be ignored
          assert_equal [test_case_execution.id],
                       css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
        end

        def test_index_with_expected_not_contains_filter
          test_case_execution = test_case_executions(:test_case_executions_001)
          get :index, params: filter_params(@project.identifier, "expected", "!~",
                                            {
                                              'expected': [test_cases(:test_cases_002).expected]
                                            },
                                            ["result", "user", "execution_date", "comment", "issue", "expected"])
          assert_response :success
          # test_case_executions_002,003 must be ignored
          assert_equal [test_case_executions(:test_case_executions_003).id,
                        test_case_executions(:test_case_executions_002).id],
                       css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
        end

        def test_index_with_expected_starts_with_filter
          test_case_execution = test_case_executions(:test_case_executions_001)
          get :index, params: filter_params(@project.identifier, "expected", "^",
                                            {
                                              'expected': ["Expected"]
                                            },
                                            ["result", "user", "execution_date", "comment", "issue", "expected"])
          assert_response :success
          assert_equal [test_case_executions(:test_case_executions_003).id,
                        test_case_executions(:test_case_executions_002).id,
                        test_case_executions(:test_case_executions_001).id],
                       css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
        end

        def test_index_with_expected_ends_with_filter
          test_case_execution = test_case_executions(:test_case_executions_001)
          get :index, params: filter_params(@project.identifier, "expected", "$",
                                            {
                                              'expected': ["2"]
                                            },
                                            ["result", "user", "execution_date", "comment", "issue", "expected"])
          assert_response :success
          # test_case_executions_002,003 must be ignored
          assert_equal [test_case_execution.id],
                       css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
        end
      end
    end

    class Order < self
      def setup
        @project = projects(:projects_003)
        login_with_permissions(@project, [:view_project, :view_issues])
        @order_params = {
          project_id: @project.identifier,
          test_plan_id: test_plans(:test_plans_003),
          test_case_id: test_cases(:test_cases_003),
        }
      end

      def test_id_order_by_desc
        ids = test_case_executions(:test_case_executions_003, :test_case_executions_002).pluck(:id)
        get :index, params: @order_params
        assert_response :success
        assert_equal ids,
                     css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_id_order_by_asc
        ids = test_case_executions(:test_case_executions_002, :test_case_executions_003).pluck(:id)
        get :index, params: @order_params.merge({ sort: "id:asc" })
        assert_response :success
        assert_equal ids,
                     css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_result_order_by_desc
        ids = test_case_executions(:test_case_executions_002, :test_case_executions_003).pluck(:id)
        get :index, params: @order_params.merge({ sort: "result:desc" })
        assert_response :success
        # should be listed in true, false order
        assert_equal ids,
                     css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_result_order_by_asc
        ids = test_case_executions(:test_case_executions_003, :test_case_executions_002).pluck(:id)
        get :index, params: @order_params.merge({ sort: "result:asc" })
        assert_response :success
        # should be listed in false, true order
        assert_equal ids,
                     css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_user_order_by_desc
        ids = test_case_executions(:test_case_executions_003, :test_case_executions_002).pluck(:id)
        get :index, params: @order_params.merge({ sort: "user:desc" })
        assert_response :success
        # should be listed in jsmith, admin
        assert_equal ids,
                     css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_user_order_by_asc
        ids = test_case_executions(:test_case_executions_002, :test_case_executions_003).pluck(:id)
        get :index, params: @order_params.merge({ sort: "user:asc" })
        assert_response :success
        # should be listed in admin, jsmith
        assert_equal ids,
                     css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_execution_date_order_by_desc
        ids = test_case_executions(:test_case_executions_003, :test_case_executions_002).pluck(:id)
        get :index, params: @order_params.merge({ sort: "execution_date:desc" })
        assert_response :success
        assert_equal ids,
                     css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_execution_date_order_by_asc
        ids = test_case_executions(:test_case_executions_002, :test_case_executions_003).pluck(:id)
        get :index, params: @order_params.merge({ sort: "execution_date:asc" })
        assert_response :success
        assert_equal ids,
                     css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_comment_order_by_desc
        ids = test_case_executions(:test_case_executions_003, :test_case_executions_002).pluck(:id)
        get :index, params: @order_params.merge({ sort: "comment:desc" })
        assert_response :success
        assert_equal ids,
                     css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_comment_order_by_asc
        ids = test_case_executions(:test_case_executions_002, :test_case_executions_003).pluck(:id)
        get :index, params: @order_params.merge({ sort: "comment:asc" })
        assert_response :success
        assert_equal ids,
                     css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_issue_order_by_desc
        skip unless postgresql? # sort by issue_id=nil behavior seems different among DB
        test_case_execution = TestCaseExecution.create(project: projects(:projects_003),
                                                       test_plan: test_plans(:test_plans_003),
                                                       test_case: test_cases(:test_cases_003),
                                                       user: users(:users_002),
                                                       issue: issues(:issues_002),
                                                       result: true,
                                                       execution_date: Time.now.strftime("%F"),
                                                       comment: "dummy")
        get :index, params: @order_params.merge({ sort: "issue:desc" })
        assert_response :success
        # test case execution without assigned issue is listed on top
        assert_equal [test_case_executions(:test_case_executions_002).id,
                      test_case_execution.id,
                      test_case_executions(:test_case_executions_003).id],
                     css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
      end

      def test_issue_order_by_asc
        skip unless postgresql? # sort by issue_id=nil behavior seems different among DB
        test_case_execution = TestCaseExecution.create(project: projects(:projects_003),
                                                       test_plan: test_plans(:test_plans_003),
                                                       test_case: test_cases(:test_cases_003),
                                                       user: users(:users_002),
                                                       issue: issues(:issues_002),
                                                       result: true,
                                                       execution_date: Time.now.strftime("%F"),
                                                       comment: "dummy")
        get :index, params: @order_params.merge({ sort: "issue:asc" })
        assert_response :success
        # test case execution without assigned issue is listed on bottom
        assert_equal [test_case_executions(:test_case_executions_003).id,
                      test_case_execution.id,
                      test_case_executions(:test_case_executions_002).id],
                     css_select("table#test_case_executions_list tr td.id").map(&:text).map(&:to_i)
      end
    end
  end

  class New < self
    def setup
      @project = projects(:projects_002)
      @test_plan = test_plans(:test_plans_002)
      @test_case = test_cases(:test_cases_001)
      login_with_permissions(@project, [:view_project, :view_issues, :add_issues])
    end

    def test_new
      assert_no_difference("TestCaseExecution.count") do
        get :new, params: {
              project_id: @project.identifier,
              test_plan_id: @test_plan.id,
              test_case_id: @test_case.id
            }
        #pp @response
        assert_response :success
        assert_select "div#content h2.inline-flex" do |h2|
          assert_equal "#{I18n.t(:label_test_plans)} » ##{@test_plan.id} #{@test_plan.name} » #{I18n.t(:label_test_cases)} ##{@test_case.id} #{@test_case.name} » #{I18n.t(:label_test_case_execution_new)}", h2.text
        end
        assert_select "select[name='test_case_execution[result]']", 1
        assert_select "select[name='test_case_execution[user]']", 1
        assert_select "input[name='test_case_execution[execution_date]']", 1
        assert_select "input[name='test_case_execution[issue_id]']", 1
        assert_select "textarea[name='test_case_execution[comment]']", 1
        assert_equal [Time.now.strftime("%F")],
                     css_select("input[name='test_case_execution[execution_date]']").collect { |node| node.attributes["value"].text }
      end
    end
  end

  class Create < self
    def setup
      login_with_permissions(projects(:projects_001, :projects_002), [:view_project, :view_issues, :add_issues])
    end

    def test_create_with_test_plan
      assert_difference("TestCaseExecution.count") do
        post :create, params: {
               project_id: projects(:projects_002).identifier,
               test_plan_id: test_plans(:test_plans_002).id,
               test_case_id: test_cases(:test_cases_001).id,
               test_case_execution: {
                 result: true, user: 1, issue_id: issues(:issues_001).id,
                 comment: "dummy", execution_date: "2022-01-01"
               }
             }
      end
      assert_equal I18n.t(:notice_successful_create), flash[:notice]
      assert_redirected_to project_test_plan_path(id: test_plans(:test_plans_002).id)
    end

    def test_create_without_test_plan
      assert_no_difference("TestCaseExecution.count") do
        post :create, params: {
               project_id: projects(:projects_002).identifier,
               test_case_id: test_cases(:test_cases_001).id,
               test_case_execution: {
                 result: true, user: 1, issue_id: issues(:issues_001).id,
                 comment: "dummy", execution_date: "2022-01-01"
               }
             }
      end
      assert_response :missing
      assert_back_to_lists_link(project_test_plans_path)
    end

    def test_create_with_nonexistent_project
      assert_no_difference("TestCaseExecution.count") do
        post :create, params: {
               project_id: NONEXISTENT_PROJECT_ID,
               test_plan_id: test_plans(:test_plans_002).id,
               test_case_id: test_cases(:test_cases_001).id,
               test_case_execution: {
                 result: true, user: 1, issue_id: issues(:issues_001).id,
                 comment: "dummy", execution_date: "2022-01-01"
               }
             }
      end
      assert_response :missing
      assert_back_to_lists_link(projects_path)
    end

    def test_create_with_nonexistent_test_plan
      assert_no_difference("TestCaseExecution.count") do
        post :create, params: {
               project_id: projects(:projects_001).identifier,
               test_plan_id: NONEXISTENT_TEST_PLAN_ID,
               test_case_id: test_cases(:test_cases_001).id,
               test_case_execution: {
                 result: true, user: 1, issue_id: issues(:issues_001).id,
                 comment: "dummy", execution_date: "2022-01-01"
               }
             }
      end
      assert_response :missing
      assert_back_to_lists_link(project_test_plans_path)
    end

    def test_create_with_nonexistent_test_case
      assert_no_difference("TestCaseExecution.count") do
        post :create, params: {
               project_id: projects(:projects_001).identifier,
               test_plan_id: test_plans(:test_plans_002).id,
               test_case_id: NONEXISTENT_TEST_CASE_ID,
               test_case_execution: {
                 result: true, user: 1, issue_id: issues(:issues_001).id,
                 comment: "dummy", execution_date: "2022-01-01"
               }
             }
      end
      assert_response :missing
      assert_back_to_lists_link(project_test_plan_test_cases_path)
    end

    def test_create_with_missing_params
      assert_no_difference("TestCaseExecution.count") do
        post :create, params: {
               project_id: projects(:projects_001).identifier,
               test_plan_id: test_plans(:test_plans_002).id,
               test_case_id: test_cases(:test_cases_001).id,
               test_case_execution: {
                 user: 1, issue_id: issues(:issues_001).id,
                 comment: "dummy", execution_date: "2022-01-01"
               }
             }
      end
      assert_response :unprocessable_entity
    end
  end

  class Show < self
    def setup
      @test_plan = test_plans(:test_plans_003)
      @test_case = test_cases(:test_cases_002)
      @test_case_execution = test_case_executions(:test_case_executions_001)
      login_with_permissions(projects(:projects_002, :projects_003), [:view_project, :view_issues])
    end

    def test_show
      get :show, params: {
            project_id: projects(:projects_003).identifier,
            test_plan_id: @test_plan.id,
            test_case_id: @test_case.id,
            id: @test_case_execution.id
          }
      assert_response :success
      assert_select "div#content h2.inline-flex" do |h2|
        assert_equal "#{I18n.t(:label_test_plans)} » ##{@test_plan.id} #{@test_plan.name} » #{I18n.t(:label_test_cases)} ##{@test_case.id} #{@test_case.name} » #{I18n.t(:label_test_case_executions)} \##{@test_case_execution.id}", h2.text
      end
      assert_select "div.subject div h3" do |h3|
        assert_equal "#{@test_case.name} #{I18n.t(:field_result)}", h3.text
      end
      assert_select "div#test_plan" do |div|
        assert_equal @test_plan.name, div.text
      end
      assert_select "div#test_case" do |div|
        assert_equal @test_case.name, div.text
      end
      assert_select "div#user" do |div|
        assert_equal @test_case_execution.user.name, div.text
      end
      assert_select "div#execution_date" do |div|
        assert_equal yyyymmdd_date(@test_case_execution.execution_date), div.text
      end
      assert_select "div#result" do |div|
        assert_equal I18n.t(:label_succeed), div.text.strip
      end
      assert_select "div#issue_id" do |div|
        assert_equal @test_case_execution.issue.to_s, div.text.strip
      end

      assert_select "div#comment" do |div|
        assert_equal @test_case_execution.comment, div.text.strip
      end
    end

    def test_show_with_nonexistent_project
      get :show, params: {
            project_id: NONEXISTENT_PROJECT_ID,
            test_plan_id: @test_plan.id,
            test_case_id: @test_case.id,
            id: @test_case_execution.id
          }
      assert_response :missing
      assert_flash_error I18n.t(:error_project_not_found)
      assert_back_to_lists_link(projects_path)
    end

    def test_show_with_nonexistent_test_plan
      get :show, params: {
            project_id: projects(:projects_002).identifier,
            test_plan_id: NONEXISTENT_TEST_PLAN_ID,
            test_case_id: @test_case.id,
            id: @test_case_execution.id
          }
      assert_response :missing
      assert_flash_error I18n.t(:error_test_plan_not_found)
      assert_back_to_lists_link(project_test_plans_path)
    end

    def test_show_with_nonexistent_test_case
      get :show, params: {
            project_id: projects(:projects_002).identifier,
            test_plan_id: @test_plan.id,
            test_case_id: NONEXISTENT_TEST_CASE_ID,
            id: @test_case_execution.id
          }
      assert_response :missing
      assert_flash_error I18n.t(:error_test_case_not_found)
      assert_back_to_lists_link(project_test_plan_test_cases_path)
    end

    def test_show_with_nonexistent_test_case_execution
      get :show, params: {
            project_id: projects(:projects_002).identifier,
            test_plan_id: @test_plan.id,
            test_case_id: @test_case.id,
            id: NONEXISTENT_TEST_CASE_EXECUTION_ID
          }
      assert_response :missing
      assert_flash_error I18n.t(:error_test_case_execution_not_found)
      assert_back_to_lists_link(project_test_plan_test_case_test_case_executions_path)
    end
  end

  class Edit < self

    def setup
      @test_plan = test_plans(:test_plans_003)
      @test_case = test_cases(:test_cases_002)
      @test_case_execution = test_case_executions(:test_case_executions_001)
      login_with_permissions(projects(:projects_002, :projects_003), [:view_project, :view_issues, :edit_issues])
    end

    def test_edit
      get :edit, params: {
            project_id: projects(:projects_003).identifier,
            test_plan_id: @test_plan.id,
            test_case_id: @test_case.id,
            id: @test_case_execution.id
          }
      assert_response :success
      assert_select "div#content h2.inline-flex" do |h2|
        assert_equal "#{I18n.t(:label_test_plans)} » ##{@test_plan.id} #{@test_plan.name} » #{I18n.t(:label_test_cases)} ##{@test_case.id} #{@test_case.name} » #{I18n.t(:label_test_case_execution_edit)} ##{@test_case_execution.id}", h2.text
      end
      assert_select "select[name='test_case_execution[result]']" do |select|
        select.first.children.each do |option|
          assert_equal I18n.t(:label_succeed), option.text if option.attributes["selected"]
        end
      end
      assert_select "select[name='test_case_execution[user]']" do |select|
        select.first.children.each do |option|
          assert_equal @test_case_execution.user.name, option.text if option.attributes["selected"]
        end
      end
      assert_select "input[name='test_case_execution[execution_date]']" do |input|
        assert_equal yyyymmdd_date(@test_case_execution.execution_date, "-"), input.first.attributes["value"].value
      end
      assert_select "input[name='test_case_execution[issue_id]']" do |input|
        assert_equal @test_case_execution.issue.id.to_s, input.first.attributes["value"].value
      end
      assert_select "textarea[name='test_case_execution[comment]']" do |textarea|
        assert_equal @test_case_execution.comment, textarea.text.strip
      end
    end

    def test_edit_with_nonexistent_project
      get :edit, params: {
            project_id: NONEXISTENT_PROJECT_ID,
            test_plan_id: @test_plan.id,
            test_case_id: @test_case.id,
            id: @test_case_execution.id
          }
      assert_response :missing
      assert_flash_error I18n.t(:error_project_not_found)
      assert_back_to_lists_link(projects_path)
    end

    def test_edit_with_nonexistent_test_plan
      get :edit, params: {
            project_id: projects(:projects_002).identifier,
            test_plan_id: NONEXISTENT_TEST_PLAN_ID,
            test_case_id: @test_case.id,
            id: @test_case_execution.id
          }
      assert_response :missing
      assert_flash_error I18n.t(:error_test_plan_not_found)
      assert_back_to_lists_link(project_test_plans_path)
    end

    def test_edit_with_nonexistent_test_case
      get :edit, params: {
            project_id: projects(:projects_002).identifier,
            test_plan_id: @test_plan.id,
            test_case_id: NONEXISTENT_TEST_CASE_ID,
            id: @test_case_execution.id
          }
      assert_response :missing
      assert_flash_error I18n.t(:error_test_case_not_found)
      assert_back_to_lists_link(project_test_plan_test_cases_path)
    end

    def test_edit_with_nonexistent_test_case_execution
      get :edit, params: {
            project_id: projects(:projects_002).identifier,
            test_plan_id: @test_plan.id,
            test_case_id: @test_case.id,
            id: NONEXISTENT_TEST_CASE_EXECUTION_ID
          }
      assert_response :missing
      assert_flash_error I18n.t(:error_test_case_execution_not_found)
      assert_back_to_lists_link(project_test_plan_test_case_test_case_executions_path)
    end
  end

  class Update < self

    def setup
      @test_plan = test_plans(:test_plans_003)
      @test_case = test_cases(:test_cases_002)
      @test_case_execution = test_case_executions(:test_case_executions_001)
      login_with_permissions(projects(:projects_001, :projects_002), [:view_project, :view_issues, :edit_issues])
    end

    def test_update
      assert_no_difference("TestCase.count") do
        put :update, params: {
              project_id: projects(:projects_003).identifier,
              test_plan_id: @test_plan.id,
              test_case_id: @test_case.id,
              id: @test_case_execution.id,
              test_case_execution: {
                result: true, user: 2, issue_id: issues(:issues_001).id,
                comment: "dummy", execution_date: "2022-01-01"
              }
            }
      end
      assert_equal I18n.t(:notice_successful_update), flash[:notice]
      assert_redirected_to project_test_plan_test_case_path(:id => @test_case.id)
    end

    def test_unassign_issue
      assert_no_difference("TestCase.count") do
        put :update, params: {
              project_id: projects(:projects_003).identifier,
              test_plan_id: @test_plan.id,
              test_case_id: @test_case.id,
              id: @test_case_execution.id,
              test_case_execution: {
                result: true, user: 2, issue_id: "",
                comment: "dummy", execution_date: "2022-01-01"
              }
            }
      end
      assert_equal I18n.t(:notice_successful_update), flash[:notice]
      @test_case_execution.reload
      assert_nil @test_case_execution.issue
      assert_redirected_to project_test_plan_test_case_path(:id => @test_case.id)
    end

    def test_update_with_nonexistent_project
      put :update, params: {
            project_id: NONEXISTENT_PROJECT_ID,
            test_plan_id: @test_plan.id,
            test_case_id: @test_case.id,
            id: @test_case_execution.id
          }
      assert_response :missing
      assert_flash_error I18n.t(:error_project_not_found)
      assert_back_to_lists_link(projects_path)
    end

    def test_update_with_nonexistent_test_plan
      put :update, params: {
            project_id: projects(:projects_003).identifier,
            test_plan_id: NONEXISTENT_TEST_PLAN_ID,
            test_case_id: @test_case.id,
            id: @test_case_execution.id
          }
      assert_response :missing
      assert_flash_error I18n.t(:error_test_plan_not_found)
      assert_back_to_lists_link(project_test_plans_path)
    end

    def test_update_with_nonexistent_test_case
      put :update, params: {
            project_id: projects(:projects_003).identifier,
            test_plan_id: @test_plan.id,
            test_case_id: NONEXISTENT_TEST_CASE_ID,
            id: @test_case_execution.id
          }
      assert_response :missing
      assert_flash_error I18n.t(:error_test_case_not_found)
      assert_back_to_lists_link(project_test_plan_test_cases_path)
    end

    def test_update_with_nonexistent_test_case_execution
      put :update, params: {
            project_id: projects(:projects_003).identifier,
            test_plan_id: @test_plan.id,
            test_case_id: @test_case.id,
            id: NONEXISTENT_TEST_CASE_EXECUTION_ID
          }
      assert_response :missing
      assert_flash_error I18n.t(:error_test_case_execution_not_found)
      assert_back_to_lists_link(project_test_plan_test_case_test_case_executions_path)
    end

    def test_update_with_missing_params
      assert_no_difference("TestCaseExecution.count") do
        put :update, params: {
              project_id: projects(:projects_003).identifier,
              test_plan_id: @test_plan.id,
              test_case_id: @test_case.id,
              id: @test_case_execution.id,
              test_case_execution: {
                user: 2, issue_id: issues(:issues_001).id,
                comment: "dummy", execution_date: "2022-01-01"
              }
            }
      end
      assert_response :unprocessable_entity
      assert_flash_error I18n.t(:error_update_failure)
    end
  end

  class Destroy < self
    def setup
      @test_plan = test_plans(:test_plans_003)
      @test_case = test_cases(:test_cases_002)
      @test_case_execution = test_case_executions(:test_case_executions_001)
      login_with_permissions(projects(:projects_002, :projects_003), [:view_project, :view_issues, :delete_issues])
    end


    def test_destroy
      assert_difference("TestCaseExecution.count", -1) do
        delete :destroy, params: {
                 project_id: projects(:projects_003).identifier,
                 test_plan_id: @test_plan.id,
                 test_case_id: @test_case.id,
                 id: @test_case_execution.id
               }
      end
      assert_equal I18n.t(:notice_successful_delete), flash[:notice]
      assert_redirected_to project_test_plan_test_case_test_case_executions_path
    end

    def test_destroy_with_nonexistent_project
      assert_no_difference("TestCaseExecution.count") do
        delete :destroy, params: {
                 project_id: NONEXISTENT_PROJECT_ID,
                 test_plan_id: @test_plan.id,
                 test_case_id: @test_case.id,
                 id: @test_case_execution.id
               }
      end
      assert_response :missing
      assert_flash_error I18n.t(:error_project_not_found)
      assert_back_to_lists_link(projects_path)
    end

    def test_destroy_with_nonexistent_test_plan
      assert_no_difference("TestCaseExecution.count") do
        delete :destroy, params: {
                 project_id: projects(:projects_003).identifier,
                 test_plan_id: NONEXISTENT_TEST_PLAN_ID,
                 test_case_id: @test_case.id,
                 id: @test_case_execution.id
               }
      end
      assert_response :missing
      assert_flash_error I18n.t(:error_test_plan_not_found)
      assert_back_to_lists_link(project_test_plans_path)
    end

    def test_destroy_with_nonexistent_test_case
      assert_no_difference("TestCaseExecution.count") do
        delete :destroy, params: {
                 project_id: projects(:projects_003).identifier,
                 test_plan_id: @test_plan.id,
                 test_case_id: NONEXISTENT_TEST_CASE_ID,
                 id: @test_case_execution.id
               }
      end
      assert_response :missing
      assert_flash_error I18n.t(:error_test_case_not_found)
      assert_back_to_lists_link(project_test_plan_test_cases_path)
    end

    def test_destroy_with_nonexistent_test_case_execution
      assert_no_difference("TestCaseExecution.count") do
        delete :destroy, params: {
                 project_id: projects(:projects_003).identifier,
                 test_plan_id: @test_plan.id,
                 test_case_id: @test_case.id,
                 id: NONEXISTENT_TEST_CASE_EXECUTION_ID
               }
      end
      assert_response :missing
      assert_flash_error I18n.t(:error_test_case_execution_not_found)
      assert_back_to_lists_link(project_test_plan_test_case_test_case_executions_path)
    end

    def test_destroy_dependent_test_case_executions
      assert_difference("TestCaseExecution.count", -1) do
        assert_difference("TestCaseExecution.count", -1) do
          delete :destroy, params: {
                   project_id: projects(:projects_003).identifier,
                   test_plan_id: @test_plan.id,
                   test_case_id: @test_case.id,
                   id: @test_case_execution.id
                 }
        end
      end
      assert_equal I18n.t(:notice_successful_delete), flash[:notice]
      assert_redirected_to project_test_plan_test_case_test_case_executions_path
    end
  end

  class ViewWithoutPermission < self
    def setup
      @project = projects(:projects_003)
      @test_plan = test_plans(:test_plans_003)
      @test_case = test_cases(:test_cases_002)
      @test_case_execution = test_case_executions(:test_case_executions_001)
      login_with_permissions(projects(:projects_001, :projects_002, :projects_003), [:view_project])
    end

    def test_index
      get :index, params: {
            project_id: @project.identifier,
            test_plan_id: test_plans(:test_plans_003).id,
            test_case_id: test_cases(:test_cases_002).id,
            c: ["result", "user", "execution_date", "comment", "issue"]
          }
      assert_response :missing
    end

    def test_new
      assert_no_difference("TestCaseExecution.count") do
        get :new, params: {
              project_id: @project.identifier,
              test_plan_id: @test_plan.id,
              test_case_id: @test_case.id
            }
      end
      assert_response :missing
    end

    def test_create
      assert_no_difference("TestCaseExecution.count") do
        post :create, params: {
               project_id: projects(:projects_002).identifier,
               test_plan_id: test_plans(:test_plans_002).id,
               test_case_id: test_cases(:test_cases_001).id,
               test_case_execution: {
                 result: true, user: 2, issue_id: issues(:issues_001).id,
                 comment: "dummy", execution_date: "2022-01-01"
               }
             }
      end
      assert_response :missing
    end

    def test_show
      get :show, params: {
            project_id: projects(:projects_003).identifier,
            test_plan_id: @test_plan.id,
            test_case_id: @test_case.id,
            id: @test_case_execution.id
          }
      assert_response :missing
    end

    def test_edit
      get :edit, params: {
            project_id: projects(:projects_003).identifier,
            test_plan_id: @test_plan.id,
            test_case_id: @test_case.id,
            id: @test_case_execution.id
          }
      assert_response :missing
    end

    def test_update
      assert_no_difference("TestCase.count") do
        put :update, params: {
              project_id: projects(:projects_003).identifier,
              test_plan_id: @test_plan.id,
              test_case_id: @test_case.id,
              id: @test_case_execution.id,
              test_case_execution: {
                result: true, user: 2, issue_id: issues(:issues_001).id,
                comment: "dummy", execution_date: "2022-01-01"
              }
            }
      end
      assert_response :missing
    end

    def test_destroy
      assert_no_difference("TestCaseExecution.count") do
        delete :destroy, params: {
                 project_id: projects(:projects_003).identifier,
                 test_plan_id: @test_plan.id,
                 test_case_id: @test_case.id,
                 id: @test_case_execution.id
               }
      end
      assert_response :missing
    end
  end

  class ModifyWithoutPermission < self
    def setup
      @test_plan = test_plans(:test_plans_003)
      @test_case = test_cases(:test_cases_002)
      @test_case_execution = test_case_executions(:test_case_executions_001)
      login_with_permissions(projects(:projects_001, :projects_002, :projects_003), [:view_project, :view_issues])
    end

    def test_create
      assert_no_difference("TestCaseExecution.count") do
        post :create, params: {
               project_id: projects(:projects_002).identifier,
               test_plan_id: test_plans(:test_plans_002).id,
               test_case_id: test_cases(:test_cases_001).id,
               test_case_execution: {
                 result: true, user: 2, issue_id: issues(:issues_001).id,
                 comment: "dummy", execution_date: "2022-01-01"
               }
             }
      end
      assert_response :forbidden
    end

    def test_update
      assert_no_difference("TestCase.count") do
        put :update, params: {
              project_id: projects(:projects_003).identifier,
              test_plan_id: @test_plan.id,
              test_case_id: @test_case.id,
              id: @test_case_execution.id,
              test_case_execution: {
                result: true, user: 2, issue_id: issues(:issues_001).id,
                comment: "dummy", execution_date: "2022-01-01"
              }
            }
      end
      assert_response :forbidden
    end

    def test_destroy
      assert_no_difference("TestCaseExecution.count") do
        delete :destroy, params: {
                 project_id: projects(:projects_003).identifier,
                 test_plan_id: @test_plan.id,
                 test_case_id: @test_case.id,
                 id: @test_case_execution.id
               }
      end
      assert_response :forbidden
    end
  end
end
