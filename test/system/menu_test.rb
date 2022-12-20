require "application_system_test_case"
require "test_helper"
require File.expand_path('../../test_helper', __FILE__)

class ApplicationSystemTestCase
  browser = ENV["UI"] ? :firefox : :headless_firefox
  driven_by :selenium, using: browser, screen_size: [1024, 900]
end

class MenuTest < ApplicationSystemTestCase
  fixtures :projects, :users, :issues, :members, :member_roles, :roles, :issue_statuses,
           :groups_users, :trackers, :projects_trackers, :enabled_modules
  fixtures :test_plans, :test_cases, :test_case_test_plans

  include ApplicationsHelper

  def setup
    @project = projects(:projects_001)
  end

  def teardown
    visit "/logout"
  end

  class AllowedAccess < self
    def setup
      super
      generate_user_with_permissions(@project, [:view_project, :view_issues, :view_test_cases, :view_test_plans, :view_test_case_executions])
      activate_module_for_projects
      log_user(@user.login, "password")
    end

    def test_menu_visible
      visit "/projects/#{@project.identifier}"
      page.document.synchronize do
        page.has_css?("div#main-menu a.testcase-management")
      end
    end
  end

  class ForbiddenAccess < self
    class ModuleStillDeactivated < self
      def setup
        super
        generate_user_with_permissions(@project, [:view_project, :view_issues, :view_test_cases, :view_test_plans, :view_test_case_executions])
        log_user(@user.login, "password")
      end
    end

    class PermissionStillMissing < self
      def setup
        super
        generate_user_with_permissions(@project, [:view_project, :view_issues])
        activate_module_for_projects
        log_user(@user.login, "password")
      end
    end

    def test_menu_invisible
      return true unless @user

      visit "/projects/#{@project.identifier}"
      page.document.synchronize do
        not page.has_css?("div#main-menu a.testcase-management")
      end
    end
  end
end
