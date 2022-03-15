require "application_system_test_case"
require "test_helper"

class ApplicationSystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1024, 900], options: {
              capabilities: Selenium::WebDriver::Remote::Capabilities.chrome(
                'goog:chromeOptions' => {
                  'prefs' => {
                    'download.default_directory' => DOWNLOADS_PATH,
                    'download.prompt_for_download' => false,
                    'plugins.plugins_disabled' => ["Chrome PDF Viewer"]
                  }
                }
              )
            }
end

class TestPlansTest < ApplicationSystemTestCase
  fixtures :projects, :issue_statuses, :users
  fixtures :test_plans

  def setup
    @project = projects(:projects_001)
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
    # TODO: select user
    fill_in 'estimated_bug', with: 1000
    # TODO: select status

    click_on I18n.t(:button_create)
  end
end
