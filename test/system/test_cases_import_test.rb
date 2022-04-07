require "application_system_test_case"
require "test_helper"

class ApplicationSystemTestCase
  options = {
    capabilities: Selenium::WebDriver::Remote::Capabilities.firefox
  }
  browser = :headless_firefox
  driven_by :selenium, using: browser, screen_size: [1024, 900], options: options
end

class TestCasesImportTest < ApplicationSystemTestCase
  fixtures :projects, :users, :issues, :members, :member_roles, :roles, :issue_statuses,
           :groups_users, :trackers, :projects_trackers, :enabled_modules
  fixtures :test_plans, :test_cases

  def test_import_test_cases_without_failures
    login_with_admin

    visit "/projects/#{projects(:projects_003).identifier}/test_cases"
    find("div.contextual>span.drdn").click
    click_on "Import"

    attach_file "file", Rails.root.join("test/fixtures/files/test_cases.csv")
    click_on "Next »"

    select "Comma", :from => "Field separator"
    select "Double quote", :from => "Field wrapper"
    select "UTF-8", :from => "Encoding"
    click_on "Next »"

    select "eCookbook Subproject 1", :from => "Project"
    select "Name", :from => "Name"
    select "Environment", :from => "Environment"
    select "User", :from => "User"
    select "Scenario", :from => "Scenario"
    select "Expected", :from => "Expected"

    assert_difference "TestCase.count", 3 do
      click_button "Import"
      assert page.has_content?("3 items have been imported")
    end
  end
end
