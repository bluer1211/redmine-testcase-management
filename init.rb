# Apply ProjectPatch to extend relation between Project and TestProject
require_dependency File.expand_path(File.join(File.dirname(__FILE__),
                                              "lib/tasks/project_patch.rb"))

Redmine::Plugin.register :testcase_management do
  name 'Redmine Plugin Testcase Management plugin'
  author 'ClearCode Inc.'
  description 'Manage test plans, test cases and execution result'
  version '1.0.0'
  url 'https://gitlab.com/clear-code/redmine-plugin-testcase-management'
  author_url 'https://www.clear-code.com'

  project_module :testcase_management do
    permission :view_test_plans, {:test_plans => :index}
  end

  permission :test_plans, {:test_plans => [:index]}, :public => true
  menu :project_menu, :testcase_management, {:controller => 'test_plans', :action => 'index', :caption => 'Test Plans'}, :param => :project_id
end

Rails.configuration.to_prepare do
  require_dependency "inherit_issue_permissions"
end
