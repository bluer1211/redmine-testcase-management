require "application_system_test_case"
require "test_helper"

class ApplicationSystemTestCaseExecution
  options = {
    capabilities: Selenium::WebDriver::Remote::Capabilities.firefox
  }
  browser = :headless_firefox
  driven_by :selenium, using: browser, screen_size: [1024, 900], options: options
end

class TestCaseExecutionsImportTest < ApplicationSystemTestCaseExecution
  fixtures :projects, :users, :issues, :members, :member_roles, :roles, :issue_statuses,
           :groups_users, :trackers, :projects_trackers, :enabled_modules
  fixtures :test_plans, :test_cases

  def test_import_test_cases_without_failures
    return true # FIX ME!!
    login_with_admin

    visit "/projects/#{projects(:projects_003).identifier}/test_case_executions"
    find("div.contextual>span.drdn").click
    click_on "Import"

    attach_file "file", Rails.root.join("test/fixtures/files/test_case_executions.csv")
    click_on "Next »"

    select "Comma", :from => "Field separator"
    select "Double quote", :from => "Field wrapper"
    select "UTF-8", :from => "Encoding"
    click_on "Next »"

    select "eCookbook Subproject 1", :from => "Project"
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

  private

  def login_with_admin
    visit "/login"
    fill_in 'username', with: "admin"
    fill_in 'password', with: "admin"
    click_button 'login-submit'
  end
end
