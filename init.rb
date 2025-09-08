require 'redmine'

# Apply ProjectPatch to extend relation between Project and TestProject
require_dependency File.expand_path(File.join(File.dirname(__FILE__),
                                              "lib/test_case_management/project_patch.rb"))
require_dependency File.expand_path(File.join(File.dirname(__FILE__),
                                              "lib/test_case_management/queries_controller_patch.rb"))
require_dependency File.expand_path(File.join(File.dirname(__FILE__),
                                              "lib/test_case_management/test_case_import_concern.rb"))

Redmine::Plugin.register :testcase_management do
  name 'Redmine Plugin Testcase Management plugin'
  author 'SENA Networks Inc.'
  description 'Manage test plans, test cases and execution result'
  version '1.6.3'
  url 'https://redmine-test-management.sena-networks.co.jp'
  author_url 'https://www.sena-networks.co.jp'

  # 支援的語言
  directory File.dirname(__FILE__)
  locales_path = File.join(directory, 'config', 'locales')
  Dir.glob(File.join(locales_path, '*.yml')).each do |locale_file|
    locale = File.basename(locale_file, '.yml')
    I18n.load_path << locale_file
    I18n.backend.store_translations(locale, YAML.load_file(locale_file))
  end

  # Plugin's modules
  project_module :testcase_management do
    #permission :manage_test_cases, {
    #  :test_cases => [:index, :show, :new, :create, :edit, :update, :destroy, :statistics, :auto_complete, :bulk_edit, :bulk_update],
    #  :test_plans => [:index, :show, :new, :create, :edit, :update, :destroy, :statistics, :assign_test_case, :unassign_test_case, :context_menu],
    #  :test_case_executions => [:index, :show, :new, :create, :edit, :update, :destroy],
    #}

    permission :view_test_cases, {
      :test_cases => [:index, :show, :statistics, :auto_complete],
    }, read: true
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
    }, read: true
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
    }, read: true
    permission :add_test_case_executions, {
      :test_cases => [:index, :show],
      :test_plans => [:index, :show],
      :test_case_executions => [:index, :show, :new, :create, :imports],
    }
    permission :edit_test_case_executions, {
      :test_cases => [:index, :show],
      :test_plans => [:index, :show],
      :test_case_executions => [:index, :show, :edit, :update, :bulk_edit, :bulk_update, :list_context_menu],
    }
    permission :delete_test_case_executions, {
      :test_case_executions => [:index, :destroy, :bulk_delete, :list_context_menu],
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

# Apply patches
Project.send(:include, TestCaseManagement::ProjectPatch)
QueriesController.send(:include, TestCaseManagement::QueriesControllerPatch)

# 包含 TestCaseImportConcern 到 ImportsController
require_dependency 'application_controller'
require_dependency 'imports_controller'

ImportsController.class_eval do
  include TestCaseManagement::TestCaseImportConcern
end
