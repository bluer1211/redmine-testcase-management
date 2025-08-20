# Redmine Testcase Management Plugin
# 
# 這個插件為 Redmine 提供完整的測試案例管理功能，包括：
# - 測試計劃管理
# - 測試案例管理  
# - 測試執行追蹤
# - 統計報表和匯入/匯出功能
# - CSV 模板下載功能
#
# 版本: 1.6.4
# 支援: Redmine 6.0.6+, Rails 7.2.2.1+
#
# 基於 SENA Networks Inc. 的原始工作開發
# 原始作者: 優人 岡田 (okada@sena-networks.co.jp)
# 原始授權: GPL v2+
# 維護交接: 自 v1.6.4 版本開始由 Jason Liu 接手維護

# 載入必要的擴展模組
require_relative 'lib/test_case_management/project_patch'
require_relative 'lib/test_case_management/queries_controller_patch'

Redmine::Plugin.register :testcase_management do
  name 'Redmine Testcase Management Plugin'
  author 'Jason Liu (GitHub: @bluer1211)'
  description 'Complete test case management system for Redmine with CSV import/export, template download, and full localization support. Features include test plans, test cases, execution tracking, statistics, and bulk operations.'
  version '1.6.4'
  url 'https://github.com/bluer1211/redmine-testcase-management'
  author_url 'https://github.com/bluer1211'
  
  # 支援的語言
  requires_redmine version_or_higher: '6.0.6'

  project_module :testcase_management do
    # 測試案例權限
    permission :view_test_cases, {
      :test_cases => [:index, :show, :statistics, :auto_complete, :template],
    }, read: true
    
    permission :add_test_cases, {
      :test_cases => [:index, :show, :new, :create, :imports, :template],
    }
    
    permission :edit_test_cases, {
      :test_cases => [:index, :show, :edit, :update, :bulk_edit, :bulk_update, :list_context_menu, :template],
    }
    
    permission :delete_test_cases, {
      :test_cases => [:index, :destroy, :bulk_delete, :list_context_menu, :template],
    }

    # 測試計劃權限
    permission :view_test_plans, {
      :test_cases => [:index, :show, :auto_complete, :template],
      :test_plans => [:index, :show, :statistics, :template],
      :test_case_executions => [:index, :show, :template],
    }, read: true
    
    permission :add_test_plans, {
      :test_cases => [:index, :show, :auto_complete, :template],
      :test_plans => [:index, :show, :new, :create, :assign_test_case, :unassign_test_case, :imports, :template],
    }
    
    permission :edit_test_plans, {
      :test_cases => [:index, :show, :auto_complete, :template],
      :test_plans => [:index, :show, :edit, :update, :bulk_edit, :bulk_update, :assign_test_case, :unassign_test_case, :show_context_menu, :list_context_menu, :template],
    }
    
    permission :delete_test_plans, {
      :test_plans => [:index, :destroy, :bulk_delete, :show_context_menu, :list_context_menu, :template],
    }

    # 測試執行權限
    permission :view_test_case_executions, {
      :test_cases => [:index, :show, :template],
      :test_plans => [:index, :show, :template],
      :test_case_executions => [:index, :show, :template],
    }, read: true
    
    permission :add_test_case_executions, {
      :test_cases => [:index, :show, :template],
      :test_plans => [:index, :show, :template],
      :test_case_executions => [:index, :show, :new, :create, :imports, :template],
    }
    
    permission :edit_test_case_executions, {
      :test_cases => [:index, :show, :template],
      :test_plans => [:index, :show, :template],
      :test_case_executions => [:index, :show, :edit, :update, :bulk_edit, :bulk_update, :list_context_menu, :template],
    }
    
    permission :delete_test_case_executions, {
      :test_case_executions => [:index, :destroy, :bulk_delete, :list_context_menu, :template],
    }
  end

  # 專案選單項目
  menu :project_menu,
       :testcase_management,
       {:controller => 'test_cases', :action => 'index', :caption => :label_testcase_management},
       :param => :project_id

  # 插件設定
  settings partial: "settings/testcase_management",
           default: {
             "test_cases_export_limit" => 10000,
             "test_plans_export_limit" => 10000,
             "test_case_executions_export_limit" => 100000,
           }
end

# 載入擴展模組到 Redmine 核心類別
# 使用安全的載入方式避免與其他插件衝突

# 擴展 Project 模型以支援測試案例管理
unless Project.included_modules.include?(TestCaseManagement::ProjectPatch)
  Project.include(TestCaseManagement::ProjectPatch)
end

# 擴展 QueriesController 以支援測試案例查詢
# 避免與 RedmineDrive 插件的衝突
unless QueriesController.included_modules.include?(TestCaseManagement::QueriesControllerPatch)
  QueriesController.include(TestCaseManagement::QueriesControllerPatch)
end
