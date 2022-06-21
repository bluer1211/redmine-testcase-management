require "application_system_test_case"
require "test_helper"
require File.expand_path('../../test_helper', __FILE__)

class ApplicationSystemTestCase
  options = {
    capabilities: Selenium::WebDriver::Remote::Capabilities.firefox
  }
  browser = ENV["UI"] ? :firefox : :headless_firefox
  driven_by :selenium, using: browser, screen_size: [1024, 900], options: options
end

class TestCaseExecutionsTest < ApplicationSystemTestCase
  fixtures :projects, :users, :issues, :members, :member_roles, :roles, :issue_statuses,
           :groups_users, :trackers, :projects_trackers, :enabled_modules
  fixtures :test_plans, :test_cases, :test_case_executions

  include ApplicationsHelper

  def setup
    activate_module_for_projects
    @project = projects(:projects_003)
    @test_plan = test_plans(:test_plans_003)
    @test_case = test_cases(:test_cases_002)
    @test_case_execution = test_case_executions(:test_case_executions_001)
  end

  def teardown
    visit "/logout"
  end

  test "visiting the index" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :view_test_case_executions])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions"
    visit path
    assert_selector "h2", text: I18n.t(:label_test_case_executions)
    assert_equal path, current_path
  end

  test "add new test case execution" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :add_issues,
                                              :view_test_plans, :view_test_case_executions, :add_test_case_executions])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions"
    visit path

    click_on I18n.t(:label_test_case_execution_new)

    select I18n.t(:label_succeed), from: 'test_case_execution[result]'
    select @user.name, from: 'test_case_execution[user]'
    assert_selector "#scenario", text: @test_case.scenario
    assert_selector "#expected", text: @test_case.expected
    fill_in 'test_case_execution[execution_date]', with: "2022-03-03"
    fill_in 'test_case_execution[comment]', with: "comment"
    fill_in 'test_case_execution[issue_id]', with: "1"

    click_button I18n.t(:button_create)
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}"
    assert_equal path, current_path
  end

  test "issue template via new" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :add_issues, :view_test_case_executions, :add_test_case_executions])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions/new"
    visit path

    issue_window = window_opened_by { click_on I18n.t(:label_issue_new) }
    sleep 1
    within_window issue_window do
      # FIXME: issue_subject can't be found
      # assert_selector "#issue_subject", text: I18n.t(:label_succeed)
      description =<<-EOS
h1. #{@test_plan.name} #{@test_case.name}

"#{@test_case.name}":#{project_test_plan_test_case_url(project_id: @project.identifier, test_plan_id: @test_plan.id, id: @test_case.id)}

h2. #{I18n.t(:field_environment)}

#{@test_case.environment}

h2. #{I18n.t(:field_scenario)}

#{@test_case.scenario}

h2. #{I18n.t(:field_expected)}

#{@test_case.expected}

h2. #{I18n.t(:field_comment)}
EOS
      port = URI.parse(current_url).port
      assert_selector "#issue_description", text: description.strip.gsub(/(127\.0\.0\.1)/, "\\1:#{port}")
    end
  end

  test "show test case execution" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :view_test_case_executions])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions/#{@test_case_execution.id}"
    visit path

    assert_selector "h2", text: "#{I18n.t(:label_test_case_executions)} \##{@test_case_execution.id}"
    assert_selector "h3", text: @test_case_execution.id

    assert_selector "#result", text: I18n.t(:label_succeed)
    assert_selector "#user", text: @test_case_execution.user.name
    assert_selector "#execution_date", text: yyyymmdd_date(@test_case_execution.execution_date)
    assert_selector "#comment", text: @test_case_execution.comment
    assert_selector "#scenario", text: @test_case.scenario
    assert_selector "#expected", text: @test_case.expected
    assert_equal path, current_path
  end

  test "update test case execution" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :edit_issues,
                                              :view_test_case_executions, :edit_test_case_executions])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions/#{@test_case_execution.id}/edit"
    visit path

    select I18n.t(:label_succeed), from: 'test_case_execution[result]'
    select @user.name, from: 'test_case_execution[user]'
    fill_in 'test_case_execution[execution_date]', with: "2022-03-03"
    fill_in 'test_case_execution[comment]', with: "comment"
    fill_in 'test_case_execution[issue_id]', with: "1"

    click_button I18n.t(:button_update)
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}"
    assert_equal path, current_path
  end

  test "delete test case execution" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :delete_issues, :view_test_case_executions, :delete_test_case_executions])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions/#{@test_case_execution.id}"
    visit path

    click_on I18n.t(:button_delete)
    accept_confirm I18n.t(:text_test_case_execution_destroy_confirmation)
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions"
    sleep 0.5 # wait until deleted
    assert_equal path, current_path
  end

  test "autocomplete issue" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :edit_issues, :view_test_case_executions, :edit_test_case_executions])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions/#{@test_case_execution.id}/edit"
    visit path

    fill_in 'test_case_execution[issue_id]', with: "subproject"
    assert_selector "ul#ui-id-1 li", count: 1, text: "Bug ##{issues(:issues_013).id}: #{issues(:issues_013).subject}"
    assert_selector "ul#ui-id-1 li", count: 1, text: "Bug ##{issues(:issues_005).id}: #{issues(:issues_005).subject}"
    page.execute_script "$('ul.ui-autocomplete li:first-child').trigger('mouseenter').click()"
    assert_equal issues(:issues_013).id.to_s, page.evaluate_script("$('#issue_id').val()")
    assert_equal path, current_path
  end

  test "use test case execution query" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :edit_issues,
                                              :view_test_plans, :view_test_cases, :view_test_case_executions, :save_queries])
    log_user(@user.login, "password")

    path = project_test_case_executions_path(@project)
    visit path

    click_on I18n.t(:button_save)

    fill_in 'query_name', with: "query"
    select "Comment", :from => "Add filter"
    fill_in 'v[comment][]', with: "Comment 3"
    click_on I18n.t(:button_save)
    assert_current_path project_test_cases_path(@project)

    visit path

    click_on "query"
    query_id = TestCaseExecutionQuery.last.id
    query_path = project_test_case_executions_path(@project) + "?query_id=#{query_id}"
    assert_current_path query_path

    # check whether filter is applied
    assert_selector "#test_case_executions_list tbody tr td.comment" do |td|
      assert_equal test_case_executions(:test_case_executions_003).comment, td.text
    end

    click_on I18n.t(:button_edit)
    fill_in 'query_name', with: "query2"
    click_on I18n.t(:button_save)

    visit query_path
    click_on "query2"
    click_on I18n.t(:button_delete)
    page.accept_confirm I18n.t(:text_are_you_sure)
    sleep 0.5
    assert_nil TestCaseExecutionQuery.where(id: query_id).first
  end

  private

  def login_with_admin
    visit "/login"
    fill_in 'username', with: "admin"
    fill_in 'password', with: "admin"
    click_button 'login-submit'
  end
end
