require "application_system_test_case"
require "test_helper"

class ApplicationSystemTestCase
  options = {
    capabilities: Selenium::WebDriver::Remote::Capabilities.firefox
  }
  browser = :headless_firefox
  driven_by :selenium, using: browser, screen_size: [1024, 900], options: options
end

class TestCaseExecutionsTest < ApplicationSystemTestCase
  fixtures :projects, :users, :issues, :members, :member_roles, :roles, :issue_statuses,
           :groups_users, :trackers, :projects_trackers, :enabled_modules
  fixtures :test_plans, :test_cases, :test_case_executions

  include ApplicationsHelper

  def setup
    @project = projects(:projects_003)
    @test_plan = test_plans(:test_plans_003)
    @test_case = test_cases(:test_cases_002)
    @test_case_execution = test_case_executions(:test_case_executions_001)
    @role = Role.generate!(:permissions => [:view_project, :view_issues, :add_issues, :edit_issues, :delete_issues])
    User.add_to_project(User.all.first, @project, @role)
    login_with_admin
  end

  def teardown
    visit "/logout"
  end

  test "visiting the index" do
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions"
    visit path
    assert_selector "h2", text: I18n.t(:label_test_case_executions)
    assert_equal path, current_path
  end

  test "add new test case execution" do
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions"
    visit path

    click_on I18n.t(:label_test_case_execution_new)

    select I18n.t(:label_succeed), from: 'test_case_execution[result]'
    select users(:users_001).name, from: 'test_case_execution[user]'
    fill_in 'test_case_execution[execution_date]', with: "2022-03-03"
    fill_in 'test_case_execution[comment]', with: "comment"
    fill_in 'test_case_execution[issue_id]', with: "1"

    click_button I18n.t(:button_create)
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}"
    assert_equal path, current_path
  end

  test "show test case execution" do
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions/#{@test_case_execution.id}"
    visit path

    assert_selector "h2", text: "#{I18n.t(:label_test_case_executions)} \##{@test_case_execution.id}"
    assert_selector "h3", text: @test_case_execution.id

    assert_selector "#result", text: I18n.t(:label_succeed)
    assert_selector "#user", text: @test_case_execution.user.name
    assert_selector "#execution_date", text: yyyymmdd_date(@test_case_execution.execution_date)
    assert_selector "#comment", text: @test_case_execution.comment
    assert_equal path, current_path
  end

  test "update test case execution" do
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions/#{@test_case_execution.id}/edit"
    visit path

    select I18n.t(:label_succeed), from: 'test_case_execution[result]'
    select users(:users_001).name, from: 'test_case_execution[user]'
    fill_in 'test_case_execution[execution_date]', with: "2022-03-03"
    fill_in 'test_case_execution[comment]', with: "comment"
    fill_in 'test_case_execution[issue_id]', with: "1"

    click_button I18n.t(:button_update)
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}"
    assert_equal path, current_path
  end

  test "delete test case execution" do
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions/#{@test_case_execution.id}"
    visit path

    click_on I18n.t(:button_delete)
    accept_confirm I18n.t(:text_test_case_execution_destroy_confirmation)
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions"
    sleep 0.5 # wait until deleted
    assert_equal path, current_path
  end

  test "autocomplete issue" do
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions/#{@test_case_execution.id}/edit"
    visit path

    fill_in 'test_case_execution[issue_id]', with: "subproject"
    assert_selector "ul#ui-id-1 li", count: 1, text: "Bug ##{issues(:issues_013).id}: #{issues(:issues_013).subject}"
    assert_selector "ul#ui-id-1 li", count: 1, text: "Bug ##{issues(:issues_005).id}: #{issues(:issues_005).subject}"
    page.execute_script "$('ul.ui-autocomplete li:first-child').trigger('mouseenter').click()"
    assert_equal issues(:issues_013).id.to_s, page.evaluate_script("$('#issue_id').val()")
    assert_equal path, current_path
  end

  private

  def login_with_admin
    visit "/login"
    fill_in 'username', with: "admin"
    fill_in 'password', with: "admin"
    click_button 'login-submit'
  end
end
