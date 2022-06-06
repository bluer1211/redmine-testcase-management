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

class TestPlansImportTest < ApplicationSystemTestCase
  fixtures :projects, :users, :issues, :members, :member_roles, :roles, :issue_statuses,
           :groups_users, :trackers, :projects_trackers, :enabled_modules
  fixtures :test_plans, :test_cases

  def setup
    activate_module_for_projects
  end

  class Scenario
    def test_import_test_cases_without_failures
      return true # FIX ME!!
      login_with_admin

      visit "/projects/#{projects(:projects_003).identifier}/test_plans"
      find("div.contextual>span.drdn").click
      click_on "Import"

      attach_file "file", Rails.root.join("test/fixtures/files/test_plans.csv")
      click_on "Next »"

      select "Comma", :from => "Field separator"
      select "Double quote", :from => "Field wrapper"
      select "UTF-8", :from => "Encoding"
      click_on "Next »"

      select "eCookbook Subproject 1", :from => "Project"
      select "Name", :from => "Name"
      select "Status", :from => "Status"
      select "User", :from => "User"
      select "Estimated Bugs", :from => "Estimated Bugs"
      select "Begin Date", :from => "Begin Date"
      select "End Date", :from => "End Date"
      select "Test Cases", :from => "Test Cases"

      assert_difference "TestPlan.count", 3 do
        click_button "Import"
        assert page.has_content?("3 items have been imported")
      end
    end
  end

  class ImportMenu < self
    def test_show_import_menu
      @project = projects(:projects_003)
      generate_user_with_permissions([@project], [:view_project,
                                                  :view_issues, :add_issues,
                                                  :view_test_plans, :add_test_plans])
      login_with(@user.login)

      visit project_test_plans_path(@project)
      # Click ... and show dropdown menu
      find("div.contextual span.drdn-trigger").click
      assert_equal I18n.t(:button_import),
                   find("div.drdn-content div.drdn-items a.icon-import").text
    end

    def test_missing_add_test_plans_permission
      @project = projects(:projects_003)
      generate_user_with_permissions([@project], [:view_project,
                                                  :view_issues,
                                                  :view_test_plans])
      login_with(@user.login)

      visit project_test_plans_path(@project)
      # Click ... and show dropdown menu
      find("div.contextual span.drdn-trigger").click
      assert_raise do
        find("div.drdn-content div.drdn-items a.icon-import")
      end
    end
  end

  private

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
