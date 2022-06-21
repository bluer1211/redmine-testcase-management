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

class TestCasesTest < ApplicationSystemTestCase
  fixtures :projects, :users, :issues, :members, :member_roles, :roles, :issue_statuses,
           :groups_users, :trackers, :projects_trackers, :enabled_modules
  fixtures :test_plans, :test_cases

  include ApplicationsHelper

  def setup
    activate_module_for_projects
    @project = projects(:projects_003)
    @test_plan = test_plans(:test_plans_002)
    @test_case = test_cases(:test_cases_001)
    #EnabledModule.create(name: "testcase_management", project: @project)
  end

  def teardown
    visit "/logout"
  end

  test "visiting test case menu via project" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :view_test_cases])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}"
    visit path

    click_on I18n.t(:label_testcase_management)

    page.document.synchronize do
      page.has_css?("h2")
    end
    assert_selector "h2", text: I18n.t(:label_test_cases)
    path = "/projects/#{@project.identifier}/test_cases"
    assert_equal path, current_path
  end

  test "visiting the index" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :view_test_cases])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases"
    visit path

    assert_selector "h2", text: I18n.t(:label_test_cases)
    assert_equal path, current_path
  end

  test "add new test case" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :add_issues, :add_test_cases])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases"
    visit path

    click_on I18n.t(:label_test_case_new)

    fill_in 'name', with: "name"
    select @user.name, from: 'test_case[user]'
    fill_in 'scenario', with: "scenario"
    fill_in 'expected', with: "expected"
    fill_in 'environment', with: "environment"

    click_button I18n.t(:button_create)
    # test case is expected to be bound with test plan, then list test plans
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}"
    assert_equal path, current_path
  end

  test "show test case" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :view_test_cases])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}"
    visit path

    assert_selector "h2", text: "#{I18n.t(:label_test_plans)}\n»\n\##{@test_plan.id} #{@test_plan.name}\n» \##{@test_case.id} #{@test_case.name}"
    assert_selector "h3", text: @test_case.name

    assert_selector "#scenario", text: @test_case.scenario
    assert_selector "#expected", text: @test_case.expected
    assert_selector "#user", text: @test_plan.user.name
    assert_selector "#environment", text: @test_case.environment
    assert_equal path, current_path
  end

  test "update test case" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :edit_issues, :view_test_cases, :edit_test_cases])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/edit"
    visit path

    fill_in 'name', with: "name"
    select @user.name, from: 'test_case[user]'
    fill_in 'scenario', with: "scenario"
    fill_in 'expected', with: "expected"
    fill_in 'environment', with: "environment"

    click_button I18n.t(:button_update)
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}"
    assert_equal path, current_path
  end

  test "update with empty environment" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :edit_issues, :view_test_cases, :edit_test_cases])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/edit"
    visit path

    fill_in 'name', with: "name"
    select @user.name, from: 'test_case[user]'
    fill_in 'scenario', with: "scenario"
    fill_in 'expected', with: "expected"

    click_button I18n.t(:button_update)
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}"
    assert_equal path, current_path
  end

  test "delete test case" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :delete_issues, :view_test_cases, :delete_test_cases])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}"
    visit path

    click_on I18n.t(:button_delete)
    page.accept_confirm I18n.t(:text_test_case_destroy_confirmation)
    sleep 1 # wait destroying
    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}"
    assert_equal path, current_path
  end

  test "minimum scenario/expected rows" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :add_issues,
                                              :view_test_cases, :add_test_cases])
    log_user(@user.login, "password")

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
    generate_user_with_permissions(@project, [:view_project, :view_issues, :edit_issues,
                                              :view_test_cases, :edit_test_cases])
    log_user(@user.login, "password")

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
    generate_user_with_permissions(@project, [:view_project, :view_issues, :edit_issues,
                                              :view_test_cases, :edit_test_cases])
    log_user(@user.login, "password")

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

  test "scenario/expected with newline" do
    skip "FIX ME!! tc.scenario may be accessible, but selector fails"
    generate_user_with_permissions(@project, [:view_project, :view_issues, :edit_issues,
                                              :view_test_cases, :edit_test_cases])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/edit"
    visit path

    fill_in 'scenario', with: "1\n2\n3"
    fill_in 'expected', with: "a\nb\nc"
    click_button I18n.t(:button_update)
    page.document.synchronize do
      page.has_css?("#flash_notice")
    end

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases"
    visit path

    page.document.synchronize do
      page.has_css?("td.scenario")
    end
    assert_selector "td.scenario" do |node|
      assert_equal "<p>1\n</p><p>2\n</p><p>3</p>", node[:innerHTML]
    end
    page.document.synchronize do
      page.has_css?("td.expected")
    end
    assert_selector "td.expected" do |node|
      assert_equal "<p>a\n</p><p>b\n</p><p>c</p>", node[:innerHTML]
    end
  end

  test "scenario/expected with max newline" do
    skip "FIX ME!! tc.scenario may be accessible, but selector fails"
    generate_user_with_permissions(@project, [:view_project, :view_issues, :edit_issues,
                                              :view_test_cases, :edit_test_cases])
    log_user(@user.login, "password")

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases/#{@test_case.id}/edit"
    visit path

    fill_in 'scenario', with: "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n11"
    fill_in 'expected', with: "a\nb\nc\nd\ne\nf\ng\nh\ni\nj\nk"
    click_button I18n.t(:button_update)
    page.document.synchronize do
      page.has_css?("#flash_notice")
    end

    path = "/projects/#{@project.identifier}/test_plans/#{@test_plan.id}/test_cases"
    visit path

    page.document.synchronize do
      page.has_css?("td.scenario")
    end
    sleep 1 # FIXME: ensure to wait
    assert_selector "td.scenario" do |node|
      assert_equal "<p>1\n</p><p>2\n</p><p>3\n</p><p>4\n</p><p>5\n</p><p>6\n</p><p>7\n</p><p>8\n</p><p>9\n</p><p>10\n11</p>", node[:innerHTML]
    end
    page.document.synchronize do
      page.has_css?("td.expected")
    end
    sleep 1 # FIXME: ensure to wait
    assert_selector "td.expected" do |node|
      assert_equal "<p>a\n</p><p>b\n</p><p>c\n</p><p>d\n</p><p>e\n</p><p>f\n</p><p>g\n</p><p>h\n</p><p>i\n</p><p>j\nk</p>", node[:innerHTML]
    end
  end

  test "bulk update independent test case user" do
    @project = projects(:projects_001)
    generate_user_with_permissions(@project, [:view_project, :view_issues, :edit_issues,
                                              :view_test_cases, :edit_test_cases])
    log_user(@user.login, "password")

    generate_test_case
    path = project_test_cases_path(@project)
    visit path

    # Click action column (show context menu)
    find("table#test_cases_list tbody tr:first-child td.buttons a").click
    # Click User folder in context menu
    find("div#context-menu ul li.folder a").click

    # Click User > <<me>> in context menu
    find("div#context-menu ul li.folder ul li:first-child a").click
    # assigned to @user
    assert_selector "table#test_cases_list tbody tr:first-child td.user" do |td|
      assert_equal @user.name, td.text
    end
    assert_equal path, current_path
  end

  test "use test case query" do
    generate_user_with_permissions(@project, [:view_project, :view_issues, :edit_issues,
                                              :view_test_plans, :view_test_cases, :save_queries])
    log_user(@user.login, "password")

    path = project_test_cases_path(@project)
    visit path

    click_on I18n.t(:button_save)

    fill_in 'query_name', with: "query"
    select "Scenario", :from => "Add filter"
    fill_in 'v[scenario][]', with: "Scenario 3"
    click_on I18n.t(:button_save)

    path = project_test_cases_path(@project)
    assert_current_path path

    click_on "query"
    query_id = TestCaseQuery.last.id
    query_path = project_test_cases_path(@project) + "?query_id=#{query_id}"
    assert_current_path query_path

    # check whether filter is applied
    assert_selector "#test_cases_list tbody tr td.scenario" do |td|
      assert_equal test_cases(:test_cases_003).scenario, td.text
    end

    click_on I18n.t(:button_edit)
    fill_in 'query_name', with: "query2"
    click_on I18n.t(:button_save)

    click_on "query2"
    click_on I18n.t(:button_delete)
    page.accept_confirm I18n.t(:text_are_you_sure)
    sleep 0.5
    assert_nil TestCaseQuery.where(id: query_id).first
  end

  private

  def login_with_admin
    visit "/login"
    fill_in 'username', with: "admin"
    fill_in 'password', with: "admin"
    click_button 'login-submit'
  end
end
