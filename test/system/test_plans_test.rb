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

class TestPlansTest < ApplicationSystemTestCase
  fixtures :projects, :users, :issues, :members, :member_roles, :roles, :issue_statuses,
           :groups_users, :trackers, :projects_trackers, :enabled_modules
  fixtures :test_plans, :test_cases, :test_case_test_plans

  include ApplicationsHelper

  def setup
    activate_module_for_projects
    @project = projects(:projects_003)
    @test_plan = test_plans(:test_plans_002)
  end

  def teardown
    visit "/logout"
  end

  test "visiting the index" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans"
    visit "/projects/#{@project.identifier}/test_plans"
    assert_selector "h2", text: I18n.t(:label_test_plans)
    assert_equal path, current_path
  end

  test "add new test plan" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :view_test_plans, :add_test_plans])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans"
    visit path

    click_on I18n.t(:label_test_plan_new)

    fill_in 'name', with: "dummy"
    fill_in 'begin_date', with: "2022-01-01"
    fill_in 'end_date', with: "2022-01-01"
    select @user.name, from: 'test_plan[user]'
    fill_in 'estimated_bug', with: 1000
    select issue_statuses(:issue_statuses_002).name, from: 'test_plan[issue_status]'

    click_button I18n.t(:button_create)
    # should be redirected to new test plan
    assert_equal "#{path}/#{TestPlan.last.id}", current_path
  end

  test "show test plan" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}"
    visit path

    assert_selector "h2", text: "#{I18n.t(:label_test_plans)}\n» \##{@test_plan.id} #{@test_plan.name}"
    assert_selector "h3", text: @test_plan.name

    assert_selector "#status", text: @test_plan.issue_status.name
    assert_selector "#estimated_bug", text: @test_plan.estimated_bug
    assert_selector "#user", text: @test_plan.user.name
    assert_selector "#begin_date", text: yyyymmdd_date(@test_plan.begin_date)
    assert_selector "#end_date", text: yyyymmdd_date(@test_plan.end_date)
    assert_equal path, current_path
  end

  test "update test plan" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :edit_issues, :view_test_plans, :edit_test_plans])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/edit"
    visit path

    fill_in 'name', with: "dummy"
    fill_in 'begin_date', with: "2022-01-01"
    fill_in 'end_date', with: "2022-01-01"
    select @user.name, from: 'test_plan[user]'
    fill_in 'estimated_bug', with: 1000
    # select In Progress
    select issue_statuses(:issue_statuses_002).name, from: 'test_plan[issue_status]'

    click_button I18n.t(:button_update)

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}"
    assert_equal path, current_path
  end

  test "delete test plan" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :delete_issues,
                                              :view_test_plans, :delete_test_plans])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}"
    visit path

    click_on I18n.t(:button_delete)
    page.accept_confirm I18n.t(:text_test_plan_destroy_confirmation)
    sleep 0.5
    path = "/projects/#{@project.identifier}/test_plans"
    assert_equal path, current_path
  end

  test "assign test case" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :edit_issues, :view_test_plans, :edit_test_plans])
    log_user(@user.login, "password")

    skip if ENV["CI"] # FIXME: fragile on CI
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}"
    visit path

    # use longer wait time for async request
    Capybara.default_max_wait_time = 5
    # show auto completion
    page.execute_script "$('#assign-test-case-form').toggle()"
    page.execute_script "$('#test_case_id').val('test').keydown();"
    page.document.synchronize do
      find("ul.ui-autocomplete li.ui-menu-item:first-child", visible: :all).visible?
    end
    page.execute_script "$('ul.ui-autocomplete li:first-child').trigger('mouseenter').click()"
    test_case = test_cases(:test_cases_003)
    page.document.synchronize do
      not find("ul.ui-autocomplete li.ui-menu-item:first-child", visible: :all).visible?
    end
    assert_equal test_case.id.to_s, page.evaluate_script("$('#test_case_id').val()")
    page.execute_script "$('input[name=\"commit\"]').click()"
    # FIXME: evaluate #related_test_cases
    assert_equal path, current_path
  end

  test "unassign test case" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :edit_issues, :view_test_plans, :edit_test_plans])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}"
    visit path

    click_on I18n.t(:button_actions)
    click_on I18n.t(:label_relation_delete)
    page.accept_confirm I18n.t(:text_are_you_sure)
    # FIXME: evaluate #related_test_cases
    assert_equal path, current_path
  end

  test "bulk unassign test case" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :edit_issues, :view_test_plans, :edit_test_plans])
    log_user(@user.login, "password")

    @test_plan = test_plans(:test_plans_003)
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}"
    visit path

    check 'check_all'
    find("table#related_test_cases tbody tr:first-child td.buttons a").click
    click_on I18n.t(:label_relation_delete)
    page.accept_confirm I18n.t(:text_are_you_sure)
    assert_equal path, current_path
    # No related test cases
    assert_equal true, page.has_css?("p.nodata")
  end

  test "bulk assign specific user" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :edit_issues,
                                              :view_test_plans, :edit_test_plans, :view_test_cases, :edit_test_cases])
    log_user(@user.login, "password")

    @test_plan = test_plans(:test_plans_003)
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}"
    visit path

    check 'check_all'
    # Click action column (show context menu)
    find("table#related_test_cases tbody tr:first-child td.buttons a").click
    # Click User folder in context menu
    find("div#context-menu ul li.folder a").click

    # Click User > <<me>> in context menu
    find("div#context-menu ul li.folder ul li:first-child a").click
    # assigned to @user
    assert_selector "table#related_test_cases tbody tr td.user" do |td|
      assert_equal @user.name, td.text
    end
    assert_equal path, current_path
  end

  test "visit test plan via index" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :view_test_plans])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans"
    visit path

    click_on @test_plan.name
    assert_selector "h2", text: "#{I18n.t(:label_test_plans)}\n» \##{@test_plan.id} #{@test_plan.name}"
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}"
    assert_equal path, current_path
  end

  test "visit test case via test plan" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :view_test_plans, :view_test_cases])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}"
    visit path

    @test_case = test_cases(:test_cases_001)
    click_on @test_case.name

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}"
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
