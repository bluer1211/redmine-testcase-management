require "application_system_test_case"
require "test_helper"

class ApplicationSystemTestCase
  options = {
    capabilities: Selenium::WebDriver::Remote::Capabilities.firefox
  }
  browser = :headless_firefox
  driven_by :selenium, using: browser, screen_size: [1024, 900], options: options
end

class TestCasesTest < ApplicationSystemTestCase
  fixtures :projects, :issue_statuses, :users
  fixtures :test_plans, :test_cases

  include ApplicationsHelper

  def setup
    @project = projects(:projects_003)
    @test_plan = test_plans(:test_plans_002)
    @test_case = test_cases(:test_cases_001)
    login_with_admin
  end

  def teardown
    visit "/logout"
  end

  test "visiting the index" do
    visit "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases"
    assert_selector "h2", text: I18n.t(:label_test_cases)
  end

  test "add new test case" do
    visit "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases"

    click_on I18n.t(:label_test_case_new)

    fill_in 'name', with: "name"
    select users(:users_001).name, from: 'test_case[user]'
    fill_in 'scenario', with: "scenario"
    fill_in 'expected', with: "expected"
    fill_in 'scheduled_date', with: "2022-03-03"
    fill_in 'environment', with: "environment"

    click_button I18n.t(:button_create)
  end

  test "show test case" do
    visit "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}"

    assert_selector "h2", text: "#{I18n.t(:label_test_cases)} \##{@test_case.id}"
    assert_selector "h3", text: @test_case.name

    assert_selector "#scenario", text: @test_case.scenario
    assert_selector "#expected", text: @test_case.expected
    assert_selector "#user", text: @test_plan.user.name
    assert_selector "#environment", text: @test_case.environment
    assert_selector "#scheduled_date", text: yyyymmdd_date(@test_case.scheduled_date)
  end

  test "update test case" do
    visit "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/edit"

    fill_in 'name', with: "name"
    select users(:users_001).name, from: 'test_case[user]'
    fill_in 'scenario', with: "scenario"
    fill_in 'expected', with: "expected"
    fill_in 'scheduled_date', with: "2022-03-03"
    fill_in 'environment', with: "environment"

    click_button I18n.t(:button_update)
  end

  test "delete test case" do
    visit "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}"

    click_on I18n.t(:button_delete)
    accept_confirm /#{I18n.t(:text_test_case_destroy_confirmation)}/
  end

  private

  def login_with_admin
    visit "/login"
    fill_in 'username', with: "admin"
    fill_in 'password', with: "admin"
    click_button 'login-submit'
  end
end
