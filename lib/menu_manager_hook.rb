# This provides ability to highlight "TestCase Management" menu for Test Cases, Test Plans and Test Case Executions pages.
# We should do this with more safer way...


module MenuManagerHook 
  include Redmine::MenuManager::MenuHelper
  alias_method :__testcase_magagement__current_menu_item, :current_menu_item

  def testcase_management_items
    @testcase_management_items ||= [:test_cases, :test_plans, :test_case_executions]
  end

  def current_menu_item
    if testcase_management_items.include?(__testcase_magagement__current_menu_item)
      :testcase_management
    else
      __testcase_magagement__current_menu_item
    end
  end
end
