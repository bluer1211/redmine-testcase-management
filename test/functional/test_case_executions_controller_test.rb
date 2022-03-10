require File.expand_path('../../test_helper', __FILE__)

class TestCaseExecutionsControllerTest < ActionController::TestCase
  fixtures :projects, :users, :issues, :issue_statuses
  fixtures :test_projects, :test_plans, :test_cases, :test_case_executions

  include ApplicationsHelper

  NONEXISTENT_PROJECT_ID = 404
  NONEXISTENT_TEST_PLAN_ID = 404
  NONEXISTENT_TEST_CASE_ID = 404
  NONEXISTENT_TEST_CASE_EXECUTION_ID = 404

  class Index < self
    def test_index
      get :index, params: {
            project_id: projects(:projects_002).identifier,
            test_plan_id: test_plans(:test_plans_003).id,
            test_case_id: test_cases(:test_cases_002).id
          }
      assert_response :success
      assert_select "tbody tr", 1
      executions = []
      assert_select "tbody tr td:first-child" do |tds|
        tds.each do |td|
          executions << td.text.to_i
        end
      end
      assert_equal [test_case_executions(:test_case_executions_001).id], executions
      columns = []
      assert_select "thead tr:first-child th" do |ths|
        ths.each do |th|
          columns << th.text
        end
      end
      assert_equal [I18n.t(:label_test_case_executions),
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
  end

  class Create < self
    def test_create
      assert_difference("TestCaseExecution.count") do
        post :create, params: { project_id: projects(:projects_003).identifier,
                                test_plan_id: test_plans(:test_plans_002).id,
                                test_case_id: test_cases(:test_cases_001).id,
                                test_case_execution: {
                                  result: true, user: 2, issue_id: issues(:issues_001).id,
                                  comment: "dummy", execution_date: "2022-01-01"
                                }
                              }
      end
      assert_equal I18n.t(:notice_successful_create), flash[:notice]
      assert_redirected_to project_test_plan_test_case_test_case_execution_path(:id => TestCaseExecution.last.id)
    end

    def test_create_with_nonexistent_project
      assert_no_difference("TestCaseExecution.count") do
        post :create, params: { project_id: NONEXISTENT_PROJECT_ID,
                                test_plan_id: test_plans(:test_plans_002).id,
                                test_case_id: test_cases(:test_cases_001).id,
                                test_case_execution: {
                                  result: true, user: 2, issue_id: issues(:issues_001).id,
                                  comment: "dummy", execution_date: "2022-01-01"
                                }
                              }
      end
      assert_response :unprocessable_entity
      assert_back_to_lists_link(projects_path)
    end

    def test_create_with_nonexistent_test_plan
      assert_no_difference("TestCaseExecution.count") do
        post :create, params: { project_id: projects(:projects_001).identifier,
                                test_plan_id: NONEXISTENT_TEST_PLAN_ID,
                                test_case_id: test_cases(:test_cases_001).id,
                                test_case_execution: {
                                  result: true, user: 2, issue_id: issues(:issues_001).id,
                                  comment: "dummy", execution_date: "2022-01-01"
                                }
                              }
      end
      assert_response :unprocessable_entity
      assert_back_to_lists_link(project_test_plans_path)
    end

    def test_create_with_nonexistent_test_case
      assert_no_difference("TestCaseExecution.count") do
        post :create, params: { project_id: projects(:projects_001).identifier,
                                test_plan_id: test_plans(:test_plans_002).id,
                                test_case_id: NONEXISTENT_TEST_CASE_ID,
                                test_case_execution: {
                                  result: true, user: 2, issue_id: issues(:issues_001).id,
                                  comment: "dummy", execution_date: "2022-01-01"
                                }
                              }
      end
      assert_response :unprocessable_entity
      assert_back_to_lists_link(project_test_plan_test_cases_path)
    end

    def test_create_with_missing_params
      assert_no_difference("TestCaseExecution.count") do
        post :create, params: { project_id: projects(:projects_001).identifier,
                                test_plan_id: test_plans(:test_plans_002).id,
                                test_case_id: test_cases(:test_cases_001).id,
                                test_case_execution: {
                                  user: 2, issue_id: issues(:issues_001).id,
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
    end

    def test_show
      get :show, params: {
            project_id: projects(:projects_002).identifier,
            test_plan_id: @test_plan.id,
            test_case_id: @test_case.id,
            id: @test_case_execution.id
          }
      assert_response :success
      assert_select "h2.inline-flex" do |h2|
        assert_equal "#{I18n.t(:label_test_case_executions)} \##{@test_case_execution.id}", h2.text
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
        assert_equal @test_case_execution.issue.to_s, " #{div.text.strip}"
      end

      assert_select "div#comment div.wiki" do |div|
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
    end

    def test_edit
      get :edit, params: {
            project_id: projects(:projects_002).identifier,
            test_plan_id: @test_plan.id,
            test_case_id: @test_case.id,
            id: @test_case_execution.id
          }
      assert_response :success
      assert_select "div#content h2" do |h2|
        assert_equal "#{I18n.t(:permission_edit_test_case_execution)} #{@test_case_execution.id}", h2.text
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
end
