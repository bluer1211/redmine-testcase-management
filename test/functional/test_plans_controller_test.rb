require File.expand_path('../../test_helper', __FILE__)

class TestPlansControllerTest < ActionController::TestCase
  fixtures :projects, :users, :issue_statuses
  fixtures :test_plans, :test_cases, :test_case_executions

  include ApplicationsHelper

  NONEXISTENT_PROJECT_ID = 404
  NONEXISTENT_TEST_PLAN_ID = 404

  def setup
    @project_id = projects(:projects_002).id
  end

  class Index < self
    def test_index
      get :index, params: { project_id: projects(:projects_001).identifier }

      assert_response :success
      # show all test plans
      assert_select "tbody tr", 5
      plans = []
      assert_select "tbody tr td:first-child" do |tds|
        tds.each do |td|
          plans << td.text
        end
      end
      assert_equal test_plans.pluck(:name), plans
      # verify columns
      columns = []
      assert_select "thead tr:first-child th" do |ths|
        ths.each do |th|
          columns << th.text
        end
      end
      assert_equal [I18n.t(:field_name),
                    I18n.t(:field_status),
                    I18n.t(:field_estimated_bug),
                    I18n.t(:field_user),
                    I18n.t(:field_begin_date),
                    I18n.t(:field_end_date)
                   ],
                   columns
      assert_select "div#content div.contextual a:first-child" do |a|
        assert_equal new_project_test_plan_path(project_id: projects(:projects_001).identifier), a.first.attributes["href"].text
        assert_equal I18n.t(:label_test_plan_new), a.text
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
    def test_show
      test_plan = test_plans(:test_plans_002)
      get :show, params: { project_id: @project_id, id: test_plan.id }

      assert_response :success
      assert_select "tbody tr", 1
      assert_select "h2.inline-flex" do |h2|
        assert_equal "Test Plans \##{test_plan.id}", h2.text
      end
      assert_select "div.subject div h3" do |h3|
        assert_equal test_plan.name, h3.text
      end
      assert_select "div#test_case_tree table tbody tr td:first-child" do |td|
        assert_equal test_cases(:test_cases_001).name, td.text
      end
      assert_select "div#test_case_tree div.contextual a:first-child" do |a|
        assert_equal new_project_test_plan_test_case_path(test_plan_id: test_plan.id), a.first.attributes["href"].text
        assert_equal I18n.t(:label_added), a.text
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
    def test_edit
      test_plan = test_plans(:test_plans_002)
      get :edit, params: { project_id: @project_id, id: test_plan.id }
      assert_select "div#content h2" do |h2|
        assert_equal "#{I18n.t(:permission_edit_test_plan)} #{test_plan.name}", h2.text
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
    def test_destroy
      test_plan = test_plans(:test_plans_001)
      assert_difference("TestPlan.count", -1) do
        assert_no_difference("TestCase.count") do
          assert_no_difference("TestCaseExecution.count") do
            delete :destroy, params: { project_id: @project_id, id: test_plan.id }
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

    def test_destroy_dependent_test_case
      test_plan = test_plans(:test_plans_002)
      assert_difference("TestPlan.count", -1) do
        assert_difference("TestCase.count", -1) do
          assert_no_difference("TestCaseExecution.count") do
            delete :destroy, params: { project_id: @project_id, id: test_plan.id }
          end
        end
      end
    end

    def test_destroy_dependent_test_case_executions
      test_plan = test_plans(:test_plans_003)
      assert_difference("TestPlan.count", -1) do
        assert_difference("TestCase.count", -2) do
          assert_difference("TestCaseExecution.count", -3) do
            delete :destroy, params: { project_id: @project_id, id: test_plan.id }
          end
        end
      end
    end
  end

  class Create < self
    def test_create_test_plan
      assert_difference("TestPlan.count") do
        project_id = projects(:projects_002).id
        post :create, params: { project_id: project_id, test_plan: { name: "test", user: 2, issue_status: 1 } }
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
end
