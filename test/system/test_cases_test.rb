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
  fixtures :projects, :users, :issues, :members, :member_roles, :roles, :issue_statuses,
           :groups_users, :trackers, :projects_trackers, :enabled_modules
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

  test "visiting test case menu via project" do
    path = "/projects/#{@project.identifier}"
    visit path

    click_on I18n.t(:label_testcase_management)

    sleep 0.5 # wait until switching
    assert_selector "h2", text: I18n.t(:label_test_cases)
    path = "/projects/#{@project.identifier}/test_cases"
    assert_equal path, current_path
  end

  test "visiting the index" do
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases"
    visit path

    assert_selector "h2", text: I18n.t(:label_test_cases)
    assert_equal path, current_path
  end

  test "add new test case" do
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases"
    visit path

    click_on I18n.t(:label_test_case_new)

    fill_in 'name', with: "name"
    select users(:users_001).name, from: 'test_case[user]'
    fill_in 'scenario', with: "scenario"
    fill_in 'expected', with: "expected"
    fill_in 'environment', with: "environment"

    click_button I18n.t(:button_create)
    # test case is expected to be bound with test plan, then list test plans
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}"
    assert_equal path, current_path
  end

  test "show test case" do
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}"
    visit path

    assert_selector "h2", text: "#{I18n.t(:label_test_plans)} » \##{@test_plan.id} #{@test_plan.name} » \##{@test_case.id} #{@test_case.name}"
    assert_selector "h3", text: @test_case.name

    assert_selector "#scenario", text: @test_case.scenario
    assert_selector "#expected", text: @test_case.expected
    assert_selector "#user", text: @test_plan.user.name
    assert_selector "#environment", text: @test_case.environment
    assert_equal path, current_path
  end

  test "update test case" do
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/edit"
    visit path

    fill_in 'name', with: "name"
    select users(:users_001).name, from: 'test_case[user]'
    fill_in 'scenario', with: "scenario"
    fill_in 'expected', with: "expected"
    fill_in 'environment', with: "environment"

    click_button I18n.t(:button_update)
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}"
    assert_equal path, current_path
  end

  test "update with empty environment" do
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/edit"
    visit path

    fill_in 'name', with: "name"
    select users(:users_001).name, from: 'test_case[user]'
    fill_in 'scenario', with: "scenario"
    fill_in 'expected', with: "expected"

    click_button I18n.t(:button_update)
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}"
    assert_equal path, current_path
  end

  test "delete test case" do
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}"
    visit path

    click_on I18n.t(:button_delete)
    page.accept_confirm I18n.t(:text_test_case_destroy_confirmation)
    sleep 1 # wait destroying
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}"
    assert_equal path, current_path
  end

  test "minimum scenario/expected rows" do
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases"
    visit path

    click_on I18n.t(:label_test_case_new)

    # textarea < 500 => rows 10
    assert_selector "#scenario" do |node|
      assert_equal ["10", "60"], [node[:rows], node[:cols]]
    end
    assert_selector "#expected" do |node|
      assert_equal ["10", "60"], [node[:rows], node[:cols]]
    end
  end

  test "scenario/expected rows" do
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/edit"
    visit path

    fill_in 'scenario', with: "a" * 550
    fill_in 'expected', with: "b" * 550
    click_button I18n.t(:button_update)
    visit path

    # 500 < textarea <= 1000 => rows 11..20
    assert_selector "#scenario" do |node|
      assert_equal ["11", "60"], [node[:rows], node[:cols]]
    end
    assert_selector "#expected" do |node|
      assert_equal ["11", "60"], [node[:rows], node[:cols]]
    end
  end

  test "maximum scenario/expected rows" do
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/edit"
    visit path

    fill_in 'scenario', with: "a" * 1050
    fill_in 'expected', with: "b" * 1050
    click_button I18n.t(:button_update)
    visit path

    # 1000 < textarea => rows 20
    assert_selector "#scenario" do |node|
      assert_equal ["20", "60"], [node[:rows], node[:cols]]
    end
    assert_selector "#expected" do |node|
      assert_equal ["20", "60"], [node[:rows], node[:cols]]
    end
  end

  private

  def login_with_admin
    visit "/login"
    fill_in 'username', with: "admin"
    fill_in 'password', with: "admin"
    click_button 'login-submit'
  end
end
