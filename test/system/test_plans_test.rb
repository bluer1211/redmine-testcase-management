require "application_system_test_case"
require "test_helper"

class ApplicationSystemTestCase
  options = {
    capabilities: Selenium::WebDriver::Remote::Capabilities.firefox
  }
  browser = :headless_firefox
  driven_by :selenium, using: browser, screen_size: [1024, 900], options: options
end

class TestPlansTest < ApplicationSystemTestCase
  fixtures :projects, :users, :issues, :members, :member_roles, :roles, :issue_statuses,
           :groups_users, :trackers, :projects_trackers, :enabled_modules
  fixtures :test_plans

  include ApplicationsHelper

  def setup
    @project = projects(:projects_003)
    @test_plan = test_plans(:test_plans_002)
    login_with_admin
  end

  def teardown
    visit "/logout"
  end

  test "visiting the index" do
    visit "/projects/#{@project.identifier}/test_plans"
    assert_selector "h2", text: I18n.t(:label_test_plans)
  end

  test "add new test plan" do
    visit "/projects/#{@project.identifier}/test_plans"

    click_on I18n.t(:label_test_plan_new)

    fill_in 'name', with: "dummy"
    fill_in 'begin_date', with: "2022-01-01"
    fill_in 'end_date', with: "2022-01-01"
    select users(:users_001).name, from: 'test_plan[user]'
    fill_in 'estimated_bug', with: 1000
    select issue_statuses(:issue_statuses_002).name, from: 'test_plan[issue_status]'

    click_button I18n.t(:button_create)
  end

  test "show test plan" do
    visit "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}"

    assert_selector "h2", text: "#{I18n.t(:label_test_plans)} \##{@test_plan.id}"
    assert_selector "h3", text: @test_plan.name

    assert_selector "#status", text: @test_plan.issue_status.name
    assert_selector "#estimated_bug", text: @test_plan.estimated_bug
    assert_selector "#user", text: @test_plan.user.name
    assert_selector "#begin_date", text: yyyymmdd_date(@test_plan.begin_date)
    assert_selector "#end_date", text: yyyymmdd_date(@test_plan.end_date)
  end

  test "update test plan" do
    visit "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/edit"

    fill_in 'name', with: "dummy"
    fill_in 'begin_date', with: "2022-01-01"
    fill_in 'end_date', with: "2022-01-01"
    # select Admin
    select users(:users_001).name, from: 'test_plan[user]'
    fill_in 'estimated_bug', with: 1000
    # select In Progress
    select issue_statuses(:issue_statuses_002).name, from: 'test_plan[issue_status]'

    click_button I18n.t(:button_update)
  end

  test "delete test plan" do
    visit "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}"

    click_on I18n.t(:button_delete)
    page.accept_confirm /#{I18n.t(:text_test_plan_destroy_confirmation)}/
  end

  private

  def login_with_admin
    visit "/login"
    fill_in 'username', with: "admin"
    fill_in 'password', with: "admin"
    click_button 'login-submit'
  end
end
