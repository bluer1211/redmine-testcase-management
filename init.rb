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
end
