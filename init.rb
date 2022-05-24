# Apply ProjectPatch to extend relation between Project and TestProject
require_dependency File.expand_path(File.join(File.dirname(__FILE__),
                                              "lib/tasks/project_patch.rb"))
require_dependency File.expand_path(File.join(File.dirname(__FILE__),
                                              "lib/tasks/queries_helper_patch.rb"))

Redmine::Plugin.register :testcase_management do
  name 'Redmine Plugin Testcase Management plugin'
  author 'ClearCode Inc.'
  description 'Manage test plans, test cases and execution result'
  version '1.1.0'
  url 'https://gitlab.com/redmine-plugin-testcase-management/redmine-plugin-testcase-management'
  author_url 'https://www.clear-code.com'

  project_module :testcase_management do
    #permission :manage_test_cases, {
    #  :test_cases => [:index, :show, :new, :create, :edit, :update, :destroy, :statistics, :auto_complete, :bulk_edit, :bulk_update],
    #  :test_plans => [:index, :show, :new, :create, :edit, :update, :destroy, :statistics, :assign_test_case, :unassign_test_case, :context_menu],
    #  :test_case_executions => [:index, :show, :new, :create, :edit, :update, :destroy],
    #}

    permission :view_test_cases, {
      :test_cases => [:index, :show, :statistics, :auto_complete],
    }
    permission :add_test_cases, {
      :test_cases => [:index, :show, :new, :create, :imports],
    }
    permission :edit_test_cases, {
      :test_cases => [:index, :show, :edit, :update, :bulk_edit, :bulk_update, :list_context_menu],
    }
    permission :delete_test_cases, {
      :test_cases => [:index, :destroy, :bulk_delete, :list_context_menu],
    }

    permission :view_test_plans, {
      :test_cases => [:index, :show, :auto_complete],
      :test_plans => [:index, :show, :statistics],
      :test_case_executions => [:index, :show],
    }
    permission :add_test_plans, {
      :test_cases => [:index, :show, :auto_complete],
      :test_plans => [:index, :show, :new, :create, :assign_test_case, :unassign_test_case, :imports],
    }
    permission :edit_test_plans, {
      :test_cases => [:index, :show, :auto_complete],
      :test_plans => [:index, :show, :edit, :update, :bulk_edit, :bulk_update, :assign_test_case, :unassign_test_case, :show_context_menu, :list_context_menu],
    }
    permission :delete_test_plans, {
      :test_plans => [:index, :destroy, :bulk_delete, :show_context_menu, :list_context_menu],
    }

    permission :view_test_case_executions, {
      :test_cases => [:index, :show],
      :test_plans => [:index, :show],
      :test_case_executions => [:index, :show],
    }
    permission :add_test_case_executions, {
      :test_cases => [:index, :show],
      :test_plans => [:index, :show],
      :test_case_executions => [:index, :show, :new, :create, :imports],
    }
    permission :edit_test_case_executions, {
      :test_cases => [:index, :show],
      :test_plans => [:index, :show],
      :test_case_executions => [:index, :show, :edit, :update],
    }
    permission :delete_test_case_executions, {
      :test_case_executions => [:index, :destroy],
    }
  end

  menu :project_menu,
       :testcase_management,
       {:controller => 'test_cases', :action => 'index', :caption => 'Test Cases'},
       :param => :project_id

  settings partial: "settings/testcase_management",
           default: {
             "test_cases_export_limit" => 10000,
             "test_plans_export_limit" => 10000,
             "test_case_executions_export_limit" => 100000,
           }
end

Rails.configuration.to_prepare do
  require_dependency "menu_manager_hook"
  require_dependency "inherit_issue_permissions"
  require_dependency "safe_attributes"
end
