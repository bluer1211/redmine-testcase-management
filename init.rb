# Apply ProjectPatch to extend relation between Project and TestProject
require_dependency File.expand_path(File.join(File.dirname(__FILE__),
                                              "lib/tasks/project_patch.rb"))
require_dependency File.expand_path(File.join(File.dirname(__FILE__),
                                              "lib/tasks/queries_helper_patch.rb"))

Redmine::Plugin.register :testcase_management do
  name 'Redmine Plugin Testcase Management plugin'
  author 'ClearCode Inc.'
  description 'Manage test plans, test cases and execution result'
  version '1.0.0'
  url 'https://gitlab.com/clear-code/redmine-plugin-testcase-management'
  author_url 'https://www.clear-code.com'

=begin
  project_module :testcase_management do
    permission :view_test_cases, :test_cases => :show
    permission :add_test_cases, :test_cases => :create
    permission :edit_test_cases, :test_cases => :update
    permission :delete_test_cases, :test_cases => :destroy

    permission :view_test_plans, :test_plans => :show
    permission :add_test_plans, :test_plans => :create
    permission :edit_test_plans, :test_plans => :update
    permission :delete_test_plans, :test_plans => :destroy

    permission :view_test_case_executions, :test_case_executions => :show
    permission :add_test_case_executions, :test_case_executions => :create
    permission :edit_test_case_executions, :test_case_executions => :update
    permission :delete_test_case_executions, :test_case_executions => :destroy
  end
=end

  permission :test_cases, {:test_cases => [:index]}, :public => true
  permission :test_plans, {:test_plans => [:index]}, :public => true

  menu :project_menu,
       :testcase_management,
       {:controller => 'test_cases', :action => 'index', :caption => 'Test Cases'},
       :param => :project_id

  settings partial: "settings/testcase_management",
           default: {
             "test_cases_export_limit" => 10000,
           }
end

Rails.configuration.to_prepare do
  require_dependency "inherit_issue_permissions"
end
