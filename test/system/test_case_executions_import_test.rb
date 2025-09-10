require "application_system_test_case"
require "test_helper"
require File.expand_path('../../test_helper', __FILE__)

class ApplicationSystemTestCase
  browser = ENV["UI"] ? :firefox : :headless_firefox
  driven_by :selenium, using: browser, screen_size: [1024, 900]
end

class TestCaseExecutionsImportTest < ApplicationSystemTestCase
  fixtures :projects, :users, :issues, :members, :member_roles, :roles, :issue_statuses,
           :groups_users, :trackers, :projects_trackers, :enabled_modules
  fixtures :test_plans, :test_cases

  def setup
    activate_module_for_projects
  end

  class ImportSucceed < self
    def test_import_test_cases_without_failures
      @project = projects(:projects_001)
      generate_user_with_permissions([@project], [:view_project,
                                                  :view_issues, :add_issues,
                                                  :view_test_plans,
                                                  :view_test_cases,
                                                  :view_test_case_executions, :add_test_case_executions])
      login_with(@user.login)
      navigate_to_mapping

      select @project.name, :from => "Project"
      select "Test Plan", :from => "Test Plan"
      select "Test Case", :from => "Test Case"
      select "User", :from => "User"
      select "Result", :from => "Result"
      select "Execution Date", :from => "Execution Date"
      select "Comment", :from => "Comment"
      select "Issue", :from => "Issue"

      assert_difference "TestCaseExecution.count", 3 do
        click_button "Import"
        assert page.has_content?("3 items have been imported")
      end
    end

    def test_missing_add_issues_permission
      @project = projects(:projects_001)
      generate_user_with_permissions([@project], [:view_project,
                                                  :view_issues,
                                                  :view_test_plans,
                                                  :view_test_cases,
                                                  :view_test_case_executions, :add_test_case_executions])
      login_with(@user.login)
      navigate_to_mapping

      select @project.name, :from => "Project"
      select "Test Plan", :from => "Test Plan"
      select "Test Case", :from => "Test Case"
      select "User", :from => "User"
      select "Result", :from => "Result"
      select "Execution Date", :from => "Execution Date"
      select "Comment", :from => "Comment"
      select "Issue", :from => "Issue"

      assert_difference "TestCaseExecution.count", 3 do
        click_button "Import"
        assert page.has_content?("3 items have been imported")
      end
    end

    def test_import_without_issue
      @project = projects(:projects_001)
      generate_user_with_permissions([@project], [:view_project,
                                                  :view_issues,
                                                  :view_test_plans,
                                                  :view_test_cases,
                                                  :view_test_case_executions, :add_test_case_executions])
      login_with(@user.login)
      navigate_to_mapping

      select @project.name, :from => "Project"
      select "Test Plan", :from => "Test Plan"
      select "Test Case", :from => "Test Case"
      select "User", :from => "User"
      select "Result", :from => "Result"
      select "Execution Date", :from => "Execution Date"
      select "Comment", :from => "Comment"

      assert_difference "TestCaseExecution.count", 3 do
        click_button "Import"
        assert page.has_content?("3 items have been imported")
      end
    end
  end

  class ImportFailure < self
    def test_missing_project_permissions
      @project = projects(:projects_003)
      generate_user_with_permissions([@project])
      login_with(@user.login)
      navigate_to_mapping

      select @project.name, :from => "Project"
      select "Test Plan", :from => "Test Plan"
      select "Test Case", :from => "Test Case"
      select "User", :from => "User"
      select "Result", :from => "Result"
      select "Execution Date", :from => "Execution Date"
      select "Comment", :from => "Comment"
      select "Issue", :from => "Issue"

      assert_difference "TestCaseExecution.count", 0 do
        click_button "Import"
        assert page.has_content?("3 out of 3 items could not be imported")
      end
    end

    def test_import_without_test_plan
      @project = projects(:projects_001)
      generate_user_with_permissions([@project], [:view_project,
                                                  :view_issues,
                                                  :view_test_plans,
                                                  :view_test_cases,
                                                  :view_test_case_executions, :add_test_case_executions])
      login_with(@user.login)
      navigate_to_mapping

      select @project.name, :from => "Project"
      select "-- Please select --", :from => "Test Plan"
      select "Test Case", :from => "Test Case"
      select "User", :from => "User"
      select "Result", :from => "Result"
      select "Execution Date", :from => "Execution Date"
      select "Comment", :from => "Comment"

      assert_difference "TestCaseExecution.count", 0 do
        click_button "Import"
        assert page.has_content?("3 out of 3 items could not be import")
      end
    end

    def test_import_without_test_case
      @project = projects(:projects_001)
      generate_user_with_permissions([@project], [:view_project,
                                                  :view_issues,
                                                  :view_test_plans,
                                                  :view_test_cases,
                                                  :view_test_case_executions, :add_test_case_executions])
      login_with(@user.login)
      navigate_to_mapping

      select @project.name, :from => "Project"
      select "Test Plan", :from => "Test Plan"
      select "-- Please select --", :from => "Test Case"
      select "User", :from => "User"
      select "Result", :from => "Result"
      select "Execution Date", :from => "Execution Date"
      select "Comment", :from => "Comment"

      assert_difference "TestCaseExecution.count", 0 do
        click_button "Import"
        assert page.has_content?("3 out of 3 items could not be import")
      end
    end
  end

  class ImportMenu < self
    def test_show_import_menu
      @project = projects(:projects_003)
      generate_user_with_permissions([@project], [:view_project,
                                                  :view_issues, :add_issues,
                                                  :view_test_case_executions, :add_test_case_executions])
      login_with(@user.login)

      visit project_test_case_executions_path(@project)
      # Click ... and show dropdown menu
      find("div.contextual span.drdn-trigger").click
      assert_equal I18n.t(:button_import),
                   find("div.drdn-content div.drdn-items a.icon-import").text
    end

    def test_missing_add_issues_permission
      @project = projects(:projects_003)
      generate_user_with_permissions([@project], [:view_project,
                                                  :view_issues,
                                                  :view_test_case_executions, :add_test_case_executions])
      login_with(@user.login)

      visit project_test_case_executions_path(@project)
      # Click ... and show dropdown menu
      find("div.contextual span.drdn-trigger").click
      assert_equal I18n.t(:button_import),
                   find("div.drdn-content div.drdn-items a.icon-import").text
    end

    def test_missing_add_test_case_executions_permission
      @project = projects(:projects_003)
      generate_user_with_permissions([@project], [:view_project,
                                                  :view_issues,
                                                  :view_test_case_executions])
      login_with(@user.login)

      visit project_test_case_executions_path(@project)
      assert_raise do
        # No dropdown menu
        find("div.contextual span.drdn-trigger")
      end
    end
  end

  private

  def navigate_to_mapping
    visit project_test_case_executions_path(@project)
    find("div.contextual>span.drdn").click
    click_on "Import"

    attach_file "file", Rails.root.join("test/fixtures/files/test_case_executions.csv")
    click_on "Next »"

    select "Comma", :from => "Field separator"
    select "Double quote", :from => "Field wrapper"
    select "UTF-8", :from => "Encoding"
    click_on "Next »"
  end

  def login_with(login_name, password="password")
    visit "/login"
    fill_in 'username', with: login_name
    fill_in 'password', with: password
    click_button 'login-submit'
  end

  def login_with_admin
    visit "/login"
    fill_in 'username', with: "admin"
    fill_in 'password', with: "admin"
    click_button 'login-submit'
  end
end
