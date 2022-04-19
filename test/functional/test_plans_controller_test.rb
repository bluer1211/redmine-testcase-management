require File.expand_path('../../test_helper', __FILE__)

class TestPlansControllerTest < ActionController::TestCase
  fixtures :projects, :users, :issues, :issue_statuses, :enumerations, :roles, :members, :member_roles,
           :groups_users, :trackers, :projects_trackers, :enabled_modules
  fixtures :test_plans, :test_cases, :test_case_executions, :test_case_test_plans

  include ApplicationsHelper

  NONEXISTENT_PROJECT_ID = 404
  NONEXISTENT_TEST_PLAN_ID = 404

  def setup
    @project_id = projects(:projects_002).id
  end

  class Index < self
    def setup
      super
      login_with_permissions(projects(:projects_001), [:view_project, :view_issues])
    end

    def test_index
      get :index, params: { project_id: projects(:projects_001).identifier }

      assert_response :success
      # show all test plans including sub projects
      assert_equal test_plans(:test_plans_005, :test_plans_003, :test_plans_002, :test_plans_001).pluck(:id),
                   css_select("table#test_plans_list tbody tr td.id").map(&:text).map(&:to_i)
      plans = []
      assert_select "table#test_plans_list tbody tr td.name" do |tds|
        tds.each do |td|
          plans << td.text
        end
      end
      assert_equal test_plans(:test_plans_005, :test_plans_003, :test_plans_002, :test_plans_001).pluck(:name), plans
      # verify columns
      columns = []
      assert_select "table#test_plans_list thead tr:first-child th" do |ths|
        ths.each do |th|
          columns << th.text
        end
      end
      assert_equal ['#',
                    I18n.t(:field_name),
                    I18n.t(:field_status),
                    I18n.t(:field_estimated_bug),
                    I18n.t(:field_user),
                    I18n.t(:field_begin_date),
                    I18n.t(:field_end_date)
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

  class Show < self
    def setup
      super
      login_with_permissions(projects(:projects_002), [:view_project, :view_issues])
    end

    def test_show
      test_plan = test_plans(:test_plans_002)
      get :show, params: { project_id: @project_id, id: test_plan.id }

      assert_response :success
      assert_select "tbody tr", 1
      assert_select "div#content h2.inline-flex" do |h2|
        assert_equal "#{I18n.t(:label_test_plans)} » \##{test_plan.id} #{test_plan.name}", h2.text
      end
      assert_select "div.subject div h3" do |h3|
        assert_equal test_plan.name, h3.text
      end
      assert_select "table#related_test_cases tbody tr td:first-child" do |td|
        assert_equal "##{test_cases(:test_cases_001).id} #{test_cases(:test_cases_001).name}", td.text
      end
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
      get :show, params: { project_id: @project_id, id: NONEXISTENT_TEST_PLAN_ID }
      assert_response :missing
      assert_flash_error I18n.t(:error_test_plan_not_found)
      assert_select "div#content a" do |link|
        link.each do |a|
          assert_equal project_test_plans_path, a.attributes["href"].text
        end
      end
    end
  end

  class Edit < self
    def setup
      super
      login_with_permissions(projects(:projects_002, :projects_003), [:view_project, :view_issues, :edit_issues])
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
      login_with_permissions(projects(:projects_002, :projects_001, :projects_003), [:view_project, :view_issues, :delete_issues])
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
      login_with_permissions(projects(:projects_002), [:view_project, :view_issues, :add_issues])
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
      login_with_permissions(projects(:projects_002), [:view_project, :view_issues, :add_issues])
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
  end

  class Assign < self
    def setup
      super
      @project = projects(:projects_003)
      @test_plan = test_plans(:test_plans_002)
      @test_case = test_cases(:test_cases_001)
      login_with_permissions(@project, [:view_project, :view_issues, :add_issues, :delete_issues])
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
      end
      assert_equal I18n.t(:notice_successful_update), flash[:notice]
      assert_redirected_to project_test_plan_path(:id => @test_plan.id)
    end

    def test_unassign_test_case
      assert_difference("TestCaseTestPlan.count", -1) do
        delete :unassign_test_case, params: {
                 project_id: @project.identifier,
                 test_plan_id: @test_plan.id,
                 test_case_id: @test_case.id
               }
      end
      assert_equal I18n.t(:notice_successful_delete), flash[:notice]
      assert_redirected_to project_test_plan_path(:id => @test_plan.id)
    end
  end

  class ViewWithoutPermission < self
    def setup
      super
      login_with_permissions(projects(:projects_001, :projects_002, :projects_003), [:view_project])
    end

    def test_index
      get :index, params: { project_id: projects(:projects_001).identifier }

      assert_response :success
      assert_select "tbody tr", 0
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
      login_with_permissions(projects(:projects_001, :projects_002, :projects_003), [:view_project, :view_issues])
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
      @project = projects(:projects_003)
      @test_plan = test_plans(:test_plans_002)
      @test_case = test_cases(:test_cases_001)
      assert_no_difference("TestCaseTestPlan.count", -1) do
        delete :unassign_test_case, params: {
                 project_id: @project.identifier,
                 test_plan_id: @test_plan.id,
                 test_case_id: @test_case.id
               }
      end

      assert_response :forbidden
    end
  end

  class Statistics < self
    def setup
      @test_case = test_cases(:test_cases_004)
      @project = @test_case.project
      @test_plan = @test_case.test_plan
      @test_case_execution = @test_case.test_case_executions.first
      @params = { project_id: @project.identifier }
      @user = users(:users_002)
      @closed_issue = issues(:issues_008)
    end

    class NoTestCase < self
    def test_statistics
      @project = projects(:projects_001)
      login_with_permissions(@project, [:view_project, :view_issues])
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
      login_with_permissions(@project, [:view_project, :view_issues])
      get :statistics, params: { project_id: @project.identifier }
      assert_response :success
      assert_select "p.nodata"
    end
    end

    class StatisticalItems < self
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

    def test_suceeded_rate
      add_test_case_with_test_case_execution({ result: false })
      login_with_permissions(@project, [:view_project, :view_issues])
      get :statistics, params: @params
      assert_response :success
      assert_equal [50], css_select("table#statistics tr td.succeeded_rate").map(&:text).map(&:to_i)
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

    def test_estimated_bug
      login_with_permissions(@project, [:view_project, :view_issues])
      get :statistics, params: @params
      assert_response :success
      assert_equal [@test_plan.estimated_bug], css_select("table#statistics tr td.estimated_bug").map(&:text).map(&:to_i)
    end

    def test_no_detected_bug
      login_with_permissions(@project, [:view_project, :view_issues])
      get :statistics, params: @params
      assert_response :success
      assert_equal [0], css_select("table#statistics tr td.detected_bug").map(&:text).map(&:to_i)
    end

    def test_detected_bug
      @project = projects(:projects_001)
      issue = Issue.generate!(project: @project)
      login_with_permissions(@project, [:view_project, :view_issues])
      get :statistics, params: { project_id: @project.identifier }
      assert_response :success
      assert_equal [2], css_select("table#statistics tr td.detected_bug").map(&:text).map(&:to_i)
    end

    def test_detected_bug_with_update
      skip "assign issue for existing test case execution may fail"
      issue = Issue.generate!(project: @project)
      @test_case_execution.update(issue: issue)
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

    def test_multiple_statistics
      @project = projects(:projects_003)
      login_with_permissions(@project, [:view_project, :view_issues])
      @test_plan = test_plans(:test_plans_002)
      add_test_case_execution_for(test_cases(:test_cases_001), { result: false, issue: @closed_issue})
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

    def test_breadcrumb
      @project = projects(:projects_003)
      login_with_permissions(@project, [:view_project, :view_issues])
      get :statistics, params: { project_id: @project.id }
      assert_select "div#content h2.inline-flex" do |h2|
        assert_equal "#{I18n.t(:label_test_plans)} » #{I18n.t(:label_test_plan_statistics)}", h2.text
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
         succeeded_rate progress_rate estimated_bug detected_bug remained_bug fixed_rate).each do |klass|
        data[klass.intern] = css_select("table#statistics tr td.#{klass}").map(&:text).map(&:to_i)
      end
      %w(name user).each do |klass|
        data[klass.intern] = css_select("table#statistics tr td.#{klass}").map(&:text)
      end
      data
    end
  end
end
