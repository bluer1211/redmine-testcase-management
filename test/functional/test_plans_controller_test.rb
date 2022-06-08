require File.expand_path('../../test_helper', __FILE__)

class TestPlansControllerTest < ActionController::TestCase
  fixtures :projects, :users, :issues, :issue_statuses, :enumerations, :roles, :members, :member_roles,
           :groups_users, :trackers, :projects_trackers, :enabled_modules
  fixtures :test_plans, :test_cases, :test_case_executions, :test_case_test_plans

  include ApplicationsHelper

  NONEXISTENT_PROJECT_ID = 404
  NONEXISTENT_TEST_PLAN_ID = 404

  class Index < self
    def setup
      super
      activate_module_for_projects
      @project_id = projects(:projects_002).id
      login_with_permissions(projects(:projects_001), [:view_project, :view_issues, :view_test_plans])
    end

    def test_index
      get :index, params: { project_id: projects(:projects_001).identifier }

      assert_response :success
      # show all test plans including sub projects
      assert_equal test_plans(:test_plans_103, :test_plans_102, :test_plans_101,
                              :test_plans_005, :test_plans_003, :test_plans_002, :test_plans_001).pluck(:id),
                   css_select("table#test_plans_list tbody tr td.id").map(&:text).map(&:to_i)
      plans = []
      assert_select "table#test_plans_list tbody tr td.name" do |tds|
        tds.each do |td|
          plans << td.text
        end
      end
      assert_equal test_plans(:test_plans_103, :test_plans_102, :test_plans_101,
                              :test_plans_005, :test_plans_003, :test_plans_002, :test_plans_001).pluck(:name), plans
      # verify columns
      columns = []
      assert_select "table#test_plans_list thead tr:first-child th" do |ths|
        ths.each do |th|
          columns << th.text.strip
        end
      end
      assert_equal ['',
                    '#',
                    I18n.t(:field_name),
                    I18n.t(:field_status),
                    I18n.t(:field_estimated_bug),
                    I18n.t(:field_user),
                    I18n.t(:field_begin_date),
                    I18n.t(:field_end_date),
                    '',
                   ],
                   columns
      assert_select "div#content div.contextual > a:first-child" do |a|
        assert_equal new_project_test_plan_path(project_id: projects(:projects_001).identifier), a.first.attributes["href"].text
        assert_equal I18n.t(:label_test_plan_new), a.text
      end
      assert_select "div#content h2.inline-flex" do |h2|
        assert_equal "#{I18n.t(:label_test_plans)}", h2.text
      end
    end

    def test_index_with_nonexistent_project
      get :index, params: { project_id: NONEXISTENT_PROJECT_ID }
      assert_response :missing
      assert_flash_error I18n.t(:error_project_not_found)
      assert_select "div#content a" do |link|
        link.each do |a|
          assert_equal projects_path, a.attributes["href"].text
        end
      end
    end
  end

  class Filter < self
    def setup
      super
      activate_module_for_projects
      @project = projects(:projects_003)
      login_with_permissions(projects(:projects_001, :projects_002, :projects_003), [:view_project, :view_issues, :view_test_plans])
    end

    class IssueStatuses < self
      def test_index_with_open_status_filter
        get :index, params: { project_id: @project.identifier,
                              f: ["issue_status_id"],
                              op: { "issue_status_id" => "o"},
                              c: ["issue_status"]
                            }
        assert_response :success
        assert_equal test_plans(:test_plans_003,
                                :test_plans_002).pluck(:id),
                     css_select("table#test_plans_list tbody tr td.id").map(&:text).map(&:to_i)
      end

      def test_index_with_closed_status_filter
        @test_plan = TestPlan.create(project: @project,
                                     name: "dummy",
                                     user: users(:users_001),
                                     issue_status: IssueStatus.named("Closed").first)
        get :index, params: { project_id: @project.identifier,
                              f: ["issue_status_id"],
                              op: { "issue_status_id" => "c"},
                            }
        assert_response :success
        assert_equal [@test_plan.id],
                     css_select("table#test_plans_list tbody tr td.id").map(&:text).map(&:to_i)
      end

      def test_index_with_status_equal_filter
        @feedback = IssueStatus.named("Feedback").first
        @test_plan = TestPlan.create(project: @project,
                                     name: "dummy",
                                     user: users(:users_001),
                                     issue_status: @feedback)
        get :index, params: filter_params(@project.identifier, "issue_status_id", "=",
                                          { "issue_status_id" => [@feedback.id] }, ["name"])
        assert_response :success
        assert_equal [@test_plan.id],
                     css_select("table#test_plans_list tbody tr td.id").map(&:text).map(&:to_i)
      end

      def test_index_with_status_not_filter
        @closed = IssueStatus.named("Closed").first
        test_plans(:test_plans_003).update(issue_status: @closed)
        get :index, params: filter_params(@project.identifier, "issue_status_id", "!",
                                          { "issue_status_id" => [@closed.id] }, ["name"])
        assert_response :success
        # test_plans_003 must be ignored
        assert_equal [test_plans(:test_plans_002).id],
                     css_select("table#test_plans_list tbody tr td.id").map(&:text).map(&:to_i)
      end

      def test_index_with_status_all_filter
        get :index, params: { project_id: @project.identifier,
                              f: ["issue_status_id"],
                              op: { "issue_status_id" => "*" },
                              c: ["name"]
                            }
        assert_response :success
        assert_equal test_plans(:test_plans_003,
                                :test_plans_002).pluck(:id),
                     css_select("table#test_plans_list tbody tr td.id").map(&:text).map(&:to_i)
      end
    end
  end

  class Show < self
    def setup
      super
      @project = projects(:projects_003)
      activate_module_for_projects
      login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
    end

    def test_show
      test_plan = test_plans(:test_plans_002)
      get :show, params: { project_id: @project.identifier, id: test_plan.id }

      assert_response :success
      assert_select "table#related_test_cases tbody tr", 1
      assert_select "div#content h2.inline-flex" do |h2|
        assert_equal "#{I18n.t(:label_test_plans)} » \##{test_plan.id} #{test_plan.name}", h2.text
      end
      assert_select "div.subject div h3" do |h3|
        assert_equal test_plan.name, h3.text
      end
      test_case = test_cases(:test_cases_001)
      assert_equal ["", "#{test_case.id}", test_case.name, test_case.environment, test_case.user.name,
                    I18n.t(:label_none), I18n.t(:label_none), test_case.scenario, test_case.expected, I18n.t(:button_actions)],
                   css_select("table#related_test_cases tbody tr td").map(&:text)
      assert_select "div#test_case_tree div.contextual a:first-child" do |a|
        assert_equal new_project_test_plan_test_case_path(test_plan_id: test_plan.id), a.first.attributes["href"].text
        assert_equal I18n.t(:label_test_case_new), a.text
      end
    end

    def test_show_with_nonexistent_project
      test_plan = test_plans(:test_plans_002)
      get :show, params: { project_id: NONEXISTENT_PROJECT_ID, id: test_plan.id }
      assert_response :missing
      assert_flash_error I18n.t(:error_project_not_found)
      assert_select "div#content a" do |link|
        link.each do |a|
          assert_equal projects_path, a.attributes["href"].text
        end
      end
    end

    def test_show_with_nonexistent_test_plan
      get :show, params: { project_id: @project.id, id: NONEXISTENT_TEST_PLAN_ID }
      assert_response :missing
      assert_flash_error I18n.t(:error_test_plan_not_found)
      assert_select "div#content a" do |link|
        link.each do |a|
          assert_equal project_test_plans_path, a.attributes["href"].text
        end
      end
    end

    def test_scenario_with_newline
      scenario = "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n11"
      test_case = test_cases(:test_cases_001).update(scenario: scenario)
      test_plan = test_plans(:test_plans_002)
      get :show, params: { project_id: @project.identifier, id: test_plan.id }
      expected = 9.times.collect { |i| "<p>#{i+1}</p>\n" }.join + "<p>10\n11</p>"
      assert_select "table#related_test_cases tbody tr:first-child td.scenario" do |node|
        assert_equal expected, node.first.inner_html
      end
    end

    def test_expected_with_newlines
      expected = "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n11"
      test_case = test_cases(:test_cases_001).update(expected: expected)
      test_plan = test_plans(:test_plans_002)
      get :show, params: { project_id: @project.identifier, id: test_plan.id }
      expected = 9.times.collect { |i| "<p>#{i+1}</p>\n" }.join + "<p>10\n11</p>"
      assert_select "table#related_test_cases tbody tr:first-child td.expected" do |node|
        assert_equal expected, node.first.inner_html
      end
    end
  end

  class Edit < self
    def setup
      super
      activate_module_for_projects
      @project_id = projects(:projects_002).id
      login_with_permissions(projects(:projects_002, :projects_003), [:view_project, :view_issues, :edit_issues, :edit_test_plans])
    end

    def test_edit
      test_plan = test_plans(:test_plans_002)
      get :edit, params: { project_id: test_plan.project.id, id: test_plan.id }
      assert_select "div#content h2.inline-flex" do |h2|
        assert_equal "#{I18n.t(:label_test_plans)} » #{I18n.t(:label_test_plan_edit)} ##{test_plan.id}", h2.text
      end
      assert_select "input[name='test_plan[name]']" do |input|
        assert_equal test_plan.name, input.first.attributes["value"].value
      end
      assert_select "input[name='test_plan[begin_date]']" do |input|
        assert_equal yyyymmdd_date(test_plan.begin_date, "-"), input.first.attributes["value"].value
      end
      assert_select "input[name='test_plan[end_date]']" do |input|
        assert_equal yyyymmdd_date(test_plan.end_date, "-"), input.first.attributes["value"].value
      end
      assert_select "input[name='test_plan[estimated_bug]']" do |input|
        assert_equal test_plan.estimated_bug.to_s, input.first.attributes["value"].value
      end
    end

    def test_edit_with_nonexistent_project
      test_plan = test_plans(:test_plans_002)
      get :edit, params: { project_id: NONEXISTENT_PROJECT_ID, id: test_plan.id }
      assert_response :missing
      assert_flash_error I18n.t(:error_project_not_found)
      assert_select "div#content a" do |link|
        link.each do |a|
          assert_equal projects_path, a.attributes["href"].text
        end
      end
    end

    def test_edit_with_nonexistent_test_plan
      get :edit, params: { project_id: @project_id, id: NONEXISTENT_TEST_PLAN_ID }
      assert_response :missing
      assert_flash_error I18n.t(:error_test_plan_not_found)
      assert_select "div#content a" do |link|
        link.each do |a|
          assert_equal project_test_plans_path, a.attributes["href"].text
        end
      end
    end
  end

  class Destroy < self
    def setup
      super
      activate_module_for_projects
      @project_id = projects(:projects_002).id
      login_with_permissions(projects(:projects_002, :projects_001, :projects_003), [:view_project, :view_issues, :delete_issues, :delete_test_plans])
    end

    def test_destroy
      test_plan = test_plans(:test_plans_001)
      assert_no_difference("TestCaseExecution.count") do
        assert_no_difference("TestCase.count") do
          assert_difference("TestPlan.count", -1) do
            delete :destroy, params: { project_id: test_plan.project.id, id: test_plan.id }
          end
        end
      end
    end

    def test_destroy_with_nonexistent_project
      test_plan = test_plans(:test_plans_001)
      delete :destroy, params: { project_id: NONEXISTENT_PROJECT_ID, id: test_plan.id }
      assert_response :missing
      assert_flash_error I18n.t(:error_project_not_found)
      assert_select "div#content a" do |link|
        link.each do |a|
          assert_equal projects_path, a.attributes["href"].text
        end
      end
    end

    def test_destroy_with_nonexistent_test_plan
      delete :destroy, params: { project_id: @project_id, id: NONEXISTENT_TEST_PLAN_ID }
      assert_response :missing
      assert_flash_error I18n.t(:error_test_plan_not_found)
      assert_select "div#content a" do |link|
        link.each do |a|
          assert_equal project_test_plans_path, a.attributes["href"].text
        end
      end
    end

    def test_destroy_dependent_test_case_executions
      test_plan = test_plans(:test_plans_003)
      assert_difference("TestCaseExecution.count", -3) do
        assert_difference("TestPlan.count", -1) do
          delete :destroy, params: { project_id: test_plan.project.id, id: test_plan.id }
        end
      end
    end
  end

  class New < self
    def setup
      super
      activate_module_for_projects
      @project_id = projects(:projects_002).id
      login_with_permissions(projects(:projects_001, :projects_002, :projects_003), [:view_project, :view_issues, :add_issues, :add_test_plans])
    end

    def test_breadcrumb
      test_plan = test_plans(:test_plans_002)
      get :new, params: { project_id: test_plan.project.id }
      assert_select "div#content h2.inline-flex" do |h2|
        assert_equal "#{I18n.t(:label_test_plans)} » #{I18n.t(:label_test_plan_new)}", h2.text
      end
    end
  end

  class Create < self
    def setup
      super
      activate_module_for_projects
      @project_id = projects(:projects_002).id
      login_with_permissions(projects(:projects_002), [:view_project, :view_issues, :add_issues, :add_test_plans])
    end

    def test_create_test_plan
      assert_difference("TestPlan.count") do
        project_id = projects(:projects_002).id
        post :create, params: { project_id: project_id, test_plan: { name: "test", user: 1, issue_status: 1 } }
      end
      assert_equal I18n.t(:notice_successful_create), flash[:notice]
      assert_redirected_to project_test_plan_path(:id => TestPlan.last.id)
    end

    def test_create_without_test_plan_name
      assert_no_difference("TestPlan.count") do
        project_id = projects(:projects_002).id
        post :create, params: { project_id: project_id, test_plan: { user: 2, issue_status: 1 } }
      end
      assert_response :unprocessable_entity
    end

    def test_create_with_maximum_test_plan_name
      assert_no_difference("TestPlan.count") do
        project_id = projects(:projects_002).id
        post :create, params: { project_id: project_id, test_plan: { name: "t" * 256, user: 2, issue_status: 1 } }
      end
      assert_response :unprocessable_entity
    end

    def test_create_and_continue_test_plan
      assert_difference("TestPlan.count") do
        project_id = projects(:projects_002).id
        post :create, params: { project_id: project_id,
                                test_plan: { name: "test", user: 1, issue_status: 1 },
                                continue: I18n.t(:button_create_and_continue) }
      end
      assert_equal I18n.t(:notice_successful_create), flash[:notice]
      assert_redirected_to new_project_test_plan_path(projects(:projects_002))
    end
  end

  class Assign < self
    def setup
      super
      activate_module_for_projects
      @test_plan = test_plans(:test_plans_002)
      @test_case = test_cases(:test_cases_001)
      @project = @test_plan.project
      login_with_permissions(@project, [:view_project, :view_issues, :edit_issues, :add_issues, :delete_issues, :view_test_cases, :view_test_plans, :edit_test_plans])
    end

    def test_assign_test_case
      assert_difference("TestCaseTestPlan.count", 1) do
        post :assign_test_case, params: {
               project_id: @project.identifier,
               test_plan_id: @test_plan.id,
               test_case_test_plan: {
                 test_case_id: test_cases(:test_cases_002).id
               }
             }
        assert_redirected_to project_test_plan_path(:id => @test_plan.id)
      end
      assert_equal I18n.t(:notice_successful_update), flash[:notice]
    end

    def test_unassign_test_case
      @test_plan.test_cases << @test_case
      @test_plan.save!
      assert_difference("TestCaseTestPlan.count", -1) do
        delete :unassign_test_case, params: {
                 project_id: @project.identifier,
                 test_plan_id: @test_plan.id,
                 id: @test_case.id
               }
        assert_redirected_to project_test_plan_path(:id => @test_plan.id)
      end
      assert_equal I18n.t(:notice_successful_delete), flash[:notice]
    end
  end

  class BulkUpdate < self
    class One < self
      def setup
        super
        activate_module_for_projects
        @project = projects(:projects_003)
        @test_plan = test_plans(:test_plans_003)
        login_as_allowed_with_permissions(@project, [:view_project, :view_issues, :edit_issues])
      end

      def test_update_status
        post :bulk_update, params: {
               project_id: @project.identifier,
               ids: [@test_plan.id],
               test_plan: {
                 user_id: @user.id
               },
               back_url: project_test_plans_path(project_id: @project.identifier)
             }
        assert_redirected_to project_test_plans_path(project_id: @project.identifier)

        get :index, params: { project_id: @project.identifier }
        assert_equal [@user.name], css_select("table#test_plans_list tbody tr:first-child td.user").map(&:text)
      end

      def test_update_begin_date
        post :bulk_update, params: {
               project_id: @project.identifier,
               ids: [@test_plan.id],
               test_plan: {
                 begin_date: "2022-01-01"
               },
               back_url: project_test_plans_path(project_id: @project.identifier)
             }
        assert_redirected_to project_test_plans_path(project_id: @project.identifier)

        get :index, params: { project_id: @project.identifier }
        assert_equal ["2022/01/01"], css_select("table#test_plans_list tbody tr:first-child td.begin_date").map(&:text)
      end

      def test_update_end_date
        post :bulk_update, params: {
               project_id: @project.identifier,
               ids: [@test_plan.id],
               test_plan: {
                 end_date: "2021-12-31"
               },
               back_url: project_test_plans_path(project_id: @project.identifier)
             }
        assert_redirected_to project_test_plans_path(project_id: @project.identifier)

        get :index, params: { project_id: @project.identifier }
        assert_equal ["2021/12/31"], css_select("table#test_plans_list tbody tr:first-child td.end_date").map(&:text)
      end
    end

    class Many < self
      def setup
        super
        activate_module_for_projects
        @project = projects(:projects_003)
        @test_plan3 = test_plans(:test_plans_003)
        @test_plan2 = test_plans(:test_plans_002)
        login_as_allowed_with_permissions(@project, [:view_project, :view_issues, :edit_issues])
      end

      def test_update_status
        post :bulk_update, params: {
               project_id: @project.identifier,
               ids: [@test_plan3.id, @test_plan2.id],
               test_plan: {
                 user_id: @user.id
               },
               back_url: project_test_plans_path(project_id: @project.identifier)
             }
        assert_redirected_to project_test_plans_path(project_id: @project.identifier)

        get :index, params: { project_id: @project.identifier }
        assert_equal [@user.name, @user.name],
                     css_select("table#test_plans_list tbody tr td.user").map(&:text)
      end

      def test_update_begin_date
        post :bulk_update, params: {
               project_id: @project.identifier,
               ids: [@test_plan3.id, @test_plan2.id],
               test_plan: {
                 begin_date: "2022-01-01"
               },
               back_url: project_test_plans_path(project_id: @project.identifier)
             }
        assert_redirected_to project_test_plans_path(project_id: @project.identifier)

        get :index, params: { project_id: @project.identifier }
        assert_equal ["2022/01/01", "2022/01/01"], css_select("table#test_plans_list tbody tr td.begin_date").map(&:text)
      end

      def test_update_end_date
        post :bulk_update, params: {
               project_id: @project.identifier,
               ids: [@test_plan3.id, @test_plan2.id],
               test_plan: {
                 end_date: "2021-12-31"
               },
               back_url: project_test_plans_path(project_id: @project.identifier)
             }
        assert_redirected_to project_test_plans_path(project_id: @project.identifier)

        get :index, params: { project_id: @project.identifier }
        assert_equal ["2021/12/31", "2021/12/31"], css_select("table#test_plans_list tbody tr td.end_date").map(&:text)
      end
    end
  end

  class BulkDelete < self
    class Many < self
      def setup
        super
        activate_module_for_projects
        @project = projects(:projects_003)
        @test_plan = test_plans(:test_plans_003)
        login_as_allowed_with_permissions(@project, [:view_project, :view_issues, :edit_issues, :delete_issues])
      end

      def test_bulk_delete
        @test_plans = []
        2.times do |index|
          @test_plans << TestPlan.create!({
                                            name: "tp#{index}",
                                            project: @project,
                                            user: @user,
                                            issue_status: issue_statuses(:issue_statuses_001)
                                          })
        end
        assert_difference("TestPlan.count", -2) do
          delete :bulk_delete, params: {
                   project_id: @project.identifier,
                   ids: [@test_plans.first.id, @test_plans.last.id],
                   back_url: project_test_plans_path(project_id: @project.identifier)
                 }
          assert_redirected_to project_test_plans_path(project_id: @project.identifier)
        end
      end
    end
  end

  class ViewWithoutPermission < self
    def setup
      super
      activate_module_for_projects
      @project_id = projects(:projects_002).id
      login_with_permissions(projects(:projects_001, :projects_002, :projects_003), [:view_project, :view_test_plans])
    end

    def test_index
      get :index, params: { project_id: projects(:projects_001).identifier }

      assert_response :forbidden
    end

    def test_show
      test_plan = test_plans(:test_plans_002)
      get :show, params: { project_id: test_plan.project.id, id: test_plan.id }

      assert_response :missing
    end
  end

  class ModifyWithoutPermission < self
    def setup
      super
      activate_module_for_projects
      @project_id = projects(:projects_002).id
      login_with_permissions(projects(:projects_001, :projects_002, :projects_003), [:view_project, :view_issues, :add_test_plans, :edit_test_plans, :delete_test_plans])
    end

    def test_create
      assert_no_difference("TestPlan.count") do
        project_id = projects(:projects_002).id
        post :create, params: { project_id: project_id, test_plan: { name: "test", user: 2, issue_status: 1 } }
      end

      assert_response :forbidden
    end

    def test_destroy
      test_plan = test_plans(:test_plans_001)
      assert_no_difference("TestCaseExecution.count") do
        assert_no_difference("TestCase.count") do
          assert_no_difference("TestPlan.count", -1) do
            delete :destroy, params: { project_id: @project_id, id: test_plan.id }
          end
        end
      end

      assert_response :forbidden
    end

    def test_edit
      test_plan = test_plans(:test_plans_002)
      get :edit, params: { project_id: test_plan.project.id, id: test_plan.id }

      assert_response :forbidden
    end

    def test_update
      test_plan = test_plans(:test_plans_002)
      get :update, params: { project_id: test_plan.project.id, id: test_plan.id, test_plan: { name: "test" } }

      assert_response :forbidden
    end

    def test_assign_test_case
      @project = projects(:projects_003)
      @test_plan = test_plans(:test_plans_002)
      @test_case = test_cases(:test_cases_001)
      assert_no_difference("TestCaseTestPlan.count", 1) do
        post :assign_test_case, params: {
               project_id: @project.identifier,
               test_plan_id: @test_plan.id,
               test_case_test_plan: {
                 test_case_id: test_cases(:test_cases_002).id
               }
             }
      end

      assert_response :forbidden
    end

    def test_unassign_test_case
      @test_plan = test_plans(:test_plans_002)
      @test_case = test_cases(:test_cases_001)
      @project = @test_plan.project;
      assert_no_difference("TestCaseTestPlan.count", -1) do
        delete :unassign_test_case, params: {
                 project_id: @project.identifier,
                 test_plan_id: @test_plan.id,
                 id: @test_case.id
               }
      end

      assert_response :forbidden
    end
  end

  class Statistics < self
    def setup
      super
      activate_module_for_projects
      @test_case = test_cases(:test_cases_004)
      @project = @test_case.project
      @test_plan = @test_case.test_plan
      @test_case_execution = @test_case.test_case_executions.first
      @params = { project_id: @project.identifier }
      login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
      @new_issue = issues(:issues_001)
      @closed_issue = issues(:issues_008)
    end

    class NoTestCase < self
      def test_statistics
        @project = projects(:projects_001)
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        @test_plan = test_plans(:test_plans_005)
        # test plan 001 should be ignored
        expected = {
          id: [@test_plan.id],
          name: [@test_plan.name],
          user: [@test_plan.user.name],
          test_cases: [@test_plan.test_cases.size],
          count_not_executed: [0],
          count_succeeded: [2],
          count_failed: [1],
          succeeded_rate: [(2/@test_plan.test_cases.size.to_f * 100).round],
          progress_rate: [100],
          estimated_bug: [@test_plan.estimated_bug],
          detected_bug: [2],
          remained_bug: [2],
          fixed_rate: [0],
        }
        assert_equal expected, actual_statistics
      end
    end

    class NoStatistics < self
      def test_no_statistics
        TestPlan.find(test_plans(:test_plans_005).id).destroy
        @project = projects(:projects_001)
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        assert_select "p.nodata"
      end
    end

    class StatisticalItems < self
      def test_count_not_executed
        TestCaseExecution.find(test_case_executions(:test_case_executions_004).id).destroy
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        assert_equal [1], css_select("table#statistics tr td.count_not_executed").map(&:text).map(&:to_i)
      end

      def test_no_count_not_executed
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        assert_equal [0], css_select("table#statistics tr td.count_not_executed").map(&:text).map(&:to_i)
      end

      def test_count_succeeded
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        assert_equal [1], css_select("table#statistics tr td.count_succeeded").map(&:text).map(&:to_i)
      end

      def test_count_succeeded_with_samedate
        add_test_case_execution_for(@test_case, {
                                      result: false,
                                      execution_date: @test_case_execution.execution_date
                                    })
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        # If execution_time of test case executions are same, greater id is referenced.
        assert_equal [0], css_select("table#statistics tr td.count_succeeded").map(&:text).map(&:to_i)
      end

      def test_no_count_succeeded
        TestCaseExecution.create(project: @project,
                                 test_plan: @test_plan,
                                 test_case: @test_case,
                                 user: @user,
                                 result: false,
                                 execution_date: Time.now.strftime("%F"),
                                 comment: "dummy")
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
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
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: @params
        assert_response :success
        assert_equal [1], css_select("table#statistics tr td.count_failed").map(&:text).map(&:to_i)
      end

      def test_no_count_failed
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: @params
        assert_response :success
        assert_equal [0], css_select("table#statistics tr td.count_failed").map(&:text).map(&:to_i)
      end

      def test_count_failed_with_samedate
        add_test_case_execution_for(@test_case, {
                                      result: false,
                                      execution_date: @test_case_execution.execution_date
                                    })
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        # If execution_time of test case executions are same, greater id is referenced.
        assert_equal [1], css_select("table#statistics tr td.count_failed").map(&:text).map(&:to_i)
      end

      def test_suceeded_rate
        add_test_case_with_test_case_execution({ result: false })
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: @params
        assert_response :success
        assert_equal [50], css_select("table#statistics tr td.succeeded_rate").map(&:text).map(&:to_i)
      end

      def test_no_progress_rate
        TestCaseExecution.find(@test_case_execution.id).destroy
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: @params
        assert_response :success
        assert_equal [0], css_select("table#statistics tr td.progress_rate").map(&:text).map(&:to_i)
      end

      def test_progress_rate_with_succeeded_only
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: @params
        assert_response :success
        # true => 1/1
        assert_equal [100], css_select("table#statistics tr td.progress_rate").map(&:text).map(&:to_i)
      end

      def test_progress_rate_with_failed_only
        add_test_case_with_test_case_execution({ result: false })
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: @params
        assert_response :success
        # false = 1/1
        assert_equal [100], css_select("table#statistics tr td.progress_rate").map(&:text).map(&:to_i)
      end

      def test_progress_rate_with_mixed_result
        add_test_case_without_test_case_execution
        add_test_case_with_test_case_execution({ result: false })
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: @params
        assert_response :success
        # true, none, false => 2/3
        assert_equal [67], css_select("table#statistics tr td.progress_rate").map(&:text).map(&:to_i)
      end

      def test_estimated_bug
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: @params
        assert_response :success
        assert_equal [@test_plan.estimated_bug], css_select("table#statistics tr td.estimated_bug").map(&:text).map(&:to_i)
      end

      def test_no_detected_bug
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: @params
        assert_response :success
        assert_equal [0], css_select("table#statistics tr td.detected_bug").map(&:text).map(&:to_i)
      end

      def test_detected_bug
        @project = projects(:projects_001)
        issue = Issue.generate!(project: @project)
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        assert_equal [2], css_select("table#statistics tr td.detected_bug").map(&:text).map(&:to_i)
      end

      def test_detected_bug_with_update
        skip "assign issue for existing test case execution may fail"
        issue = Issue.generate!(project: @project)
        @test_case_execution.update(issue: issue)
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: @params
        assert_response :success
        assert_equal [1], css_select("table#statistics tr td.detected_bug").map(&:text).map(&:to_i)
      end

      def test_no_remained_bug
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: @params
        assert_response :success
        assert_equal [0], css_select("table#statistics tr td.remained_bug").map(&:text).map(&:to_i)
      end

      def test_remained_bug
        @project = projects(:projects_001)
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
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
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        # associated issues 2 - 1 (closed)
        assert_equal [1], css_select("table#statistics tr td.remained_bug").map(&:text).map(&:to_i)
      end

      def test_no_fixed_rate
        TestCaseExecution.find(@test_case_execution.id).destroy
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
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
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
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
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
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
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        # associated issues 3/3
        assert_equal [100], css_select("table#statistics tr td.fixed_rate").map(&:text).map(&:to_i)
      end
    end

    class MultipleTestPlan < self
      def test_multiple_statistics
        @project = projects(:projects_003)
        @test_plan = test_plans(:test_plans_002)
        add_test_case_execution_for(test_cases(:test_cases_001), { result: false,
                                                                   execution_date: Time.now,
                                                                   issue: @closed_issue})
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: { project_id: @project.identifier }
        assert_response :success
        @first_test_plan = test_plans(:test_plans_002)
        @second_test_plan = test_plans(:test_plans_003)
        expected = {
          id: [@second_test_plan.id, @first_test_plan.id],
          name: [@second_test_plan.name, @first_test_plan.name],
          user: [@second_test_plan.user.name, @first_test_plan.user.name],
          test_cases: [@second_test_plan.test_cases.size, @first_test_plan.test_cases.size],
          count_not_executed: [0, 0],
          count_succeeded: [1, 0],
          count_failed: [1, 1],
          succeeded_rate: [
            (1/@second_test_plan.test_cases.size.to_f * 100).round,
            (0/@first_test_plan.test_cases.size.to_f * 100).round,
          ],
          progress_rate: [100, 100],
          estimated_bug: [@second_test_plan.estimated_bug, @first_test_plan.estimated_bug],
          detected_bug: [2, 1],
          remained_bug: [2, 0],
          fixed_rate: [0, 100],
        }
        assert_equal expected, actual_statistics
      end
    end

    class ReassingedTestCase < self
      def test_reassigned
        @test_case = test_cases(:test_cases_003)
        @test_plan = test_plans(:test_plans_002)
        @project = @test_plan.project
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans, :edit_test_plans])
        # reassign TC=3 under TP=2
        TestCaseTestPlan.create(test_plan: @test_plan,
                                test_case: @test_case)
        add_test_case_execution_for(@test_case, { result: false,
                                                  execution_date: @test_case_execution.execution_date,
                                                  issue: @new_issue })
        add_test_case_execution_for(@test_case, { result: true,
                                                  execution_date: @test_case_execution.execution_date,
                                                  issue: nil })
        get :statistics, params: { project_id: @project.id }
        @first_test_plan = test_plans(:test_plans_002)
        @second_test_plan = test_plans(:test_plans_003)
        # TP2 - TC1
        # TP2 - TC3 - TCE,TCE (true)
        # TP3 - TC2 - TCE (true)
        # TP3 - TC3 - TCE2,TCE3 (false)
        expected = {
          id: [@second_test_plan.id, @first_test_plan.id],
          name: [@second_test_plan.name, @first_test_plan.name],
          user: [@second_test_plan.user.name, @first_test_plan.user.name],
          test_cases: [@second_test_plan.test_cases.size, @first_test_plan.test_cases.size],
          count_not_executed: [0, 1],
          count_succeeded: [1, 1],
          count_failed: [1, 0],
          succeeded_rate: [
            (1/@second_test_plan.test_cases.size.to_f * 100).round,
            (1/@first_test_plan.test_cases.size.to_f * 100).round,
          ],
          progress_rate: [100, 50],
          estimated_bug: [@second_test_plan.estimated_bug, @first_test_plan.estimated_bug],
          detected_bug: [2, 0],
          remained_bug: [2, 0],
          fixed_rate: [0, 0],
        }
        assert_equal expected, actual_statistics
      end
    end

    class MenuItems < self
      def test_breadcrumb
        @project = projects(:projects_003)
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
        get :statistics, params: { project_id: @project.id }
        assert_select "div#content h2.inline-flex" do |h2|
          assert_equal "#{I18n.t(:label_test_plans)} » #{I18n.t(:label_test_plan_statistics)}", h2.text
        end
      end
    end

    private

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
    end

    def add_test_case_execution_for(test_case, options={ result: true, issue: nil, execution_date: Time.now.strftime("%F")})
      TestCaseExecution.create(project: @project,
                               test_plan: @test_plan,
                               test_case: test_case,
                               user: @user,
                               result: options[:result],
                               issue: options[:issue],
                               execution_date: options[:execution_date],
                               comment: "dummy")
    end

    def actual_statistics
      data = {}
      %w(id test_cases count_not_executed count_succeeded count_failed
         succeeded_rate progress_rate estimated_bug detected_bug remained_bug fixed_rate).each do |klass|
        data[klass.intern] = css_select("table#statistics tr td.#{klass}").map(&:text).map(&:to_i)
      end
      %w(name user).each do |klass|
        data[klass.intern] = css_select("table#statistics tr td.#{klass}").map(&:text)
      end
      data
    end
  end

  class ForbiddenAccess < self
    def setup
      @test_plan = test_plans(:test_plans_001)
      @project = @test_plan.project
    end

    class ModuleStillDeactivated < self
      def setup
        super
        login_with_permissions(@project, [:view_project, :view_issues, :view_test_plans, :add_test_plans, :edit_test_plans, :delete_test_plans])
      end
    end

    class PermissionStillMissing < self
      def setup
        super
        login_with_permissions(@project, [:view_project, :view_issues])
        activate_module_for_projects
      end
    end

    def test_index
      get :index, params: { project_id: @project.identifier }
      assert_response :forbidden
    end

    def test_show
      get :show, params: { project_id: @project.identifier, id: @test_plan.id }
      assert_response :forbidden
    end

    def test_new
      get :new, params: { project_id: @project.identifier }
      assert_response :forbidden
    end

    def test_create
      assert_no_difference("TestPlan.count") do
        post :create, params: {
               project_id: @project.identifier,
               test_plan: {
                 name: "test",
                 user: 1,
                 issue_status: 1,
               },
             }
      end
      assert_response :forbidden
    end

    def test_edit
      get :edit, params: { project_id: @project.identifier, id: @test_plan.id }
      assert_response :forbidden
    end

    def test_update
      put :update, params: {
            project_id: @project.identifier,
            id: @test_plan.id,
            test_plan: {
              name: "test",
            },
          }
      assert_response :forbidden
    end

    def test_destroy
      assert_no_difference("TestPlan.count") do
        delete :destroy, params: {
                 project_id: @project.identifier,
                 id: @test_plan.id,
               }
      end
      assert_response :forbidden
    end

    def test_assign_test_case
      assert_no_difference("TestCaseTestPlan.count", 1) do
        post :assign_test_case, params: {
               project_id: @project.identifier,
               test_plan_id: @test_plan.id,
               test_case_test_plan: {
                 test_case_id: test_cases(:test_cases_002).id
               }
             }
      end
      assert_response :forbidden
    end

    def test_unassign_test_case
      @test_plan = test_plans(:test_plans_002)
      @test_case = test_cases(:test_cases_001)
      @project = @test_plan.project
      assert_no_difference("TestCaseTestPlan.count", -1) do
        delete :unassign_test_case, params: {
                 project_id: @project.identifier,
                 test_plan_id: @test_plan.id,
                 id: @test_case.id,
               }
      end
      assert_response :forbidden
    end

    def test_statistics
      get :statistics, params: { project_id: @project.identifier }
      assert_response :forbidden
    end
  end
end
