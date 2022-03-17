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
  fixtures :projects, :issue_statuses, :users
  fixtures :test_plans, :test_cases, :test_case_executions

  include ApplicationsHelper

  def setup
    @project = projects(:projects_003)
    @test_plan = test_plans(:test_plans_003)
    @test_case = test_cases(:test_cases_002)
    @test_case_execution = test_case_executions(:test_case_executions_001)
    login_with_admin
  end

  def teardown
    visit "/logout"
  end

  test "visiting the index" do
    visit "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions"
    assert_selector "h2", text: I18n.t(:label_test_case_executions)
  end

  test "add new test case execution" do
    visit "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions"

    click_on I18n.t(:label_test_case_execution_new)

    select I18n.t(:label_succeed), from: 'test_case_execution[result]'
    select users(:users_001).name, from: 'test_case_execution[user]'
    fill_in 'test_case_execution[execution_date]', with: "2022-03-03"
    fill_in 'test_case_execution[comment]', with: "comment"
    fill_in 'test_case_execution[issue_id]', with: "1"

    click_button I18n.t(:button_create)
  end

  test "show test case execution" do
    visit "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions/#{@test_case_execution.id}"

    assert_selector "h2", text: "#{I18n.t(:label_test_case_executions)} \##{@test_case_execution.id}"
    assert_selector "h3", text: @test_case_execution.id

    assert_selector "#result", text: I18n.t(:label_succeed)
    assert_selector "#user", text: @test_case_execution.user.name
    assert_selector "#execution_date", text: yyyymmdd_date(@test_case_execution.execution_date)
    assert_selector "#comment", text: @test_case_execution.comment
  end

  test "update test case execution" do
    visit "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions/#{@test_case_execution.id}/edit"

    select I18n.t(:label_succeed), from: 'test_case_execution[result]'
    select users(:users_001).name, from: 'test_case_execution[user]'
    fill_in 'test_case_execution[execution_date]', with: "2022-03-03"
    fill_in 'test_case_execution[comment]', with: "comment"
    fill_in 'test_case_execution[issue_id]', with: "1"

    click_button I18n.t(:button_update)
  end

  test "delete test case" do
    visit "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/test_case_executions/#{@test_case_execution.id}"

    sleep 3
    click_on I18n.t(:button_delete)
    accept_confirm I18n.t(:text_test_case_execution_destroy_confirmation)
  end

  private

  def login_with_admin
    visit "/login"
    fill_in 'username', with: "admin"
    fill_in 'password', with: "admin"
    click_button 'login-submit'
  end
end
