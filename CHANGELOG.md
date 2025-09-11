# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 延伸開發說明

本插件基於 SENA Networks Inc. 的開源專案進行延伸開發，自 v1.6.2 版本開始由 Jason Liu (@bluer1211) 進行功能擴展和改進。

- **原始作者**: 優人 岡田 (okada@sena-networks.co.jp)
- **原始公司**: SENA Networks Inc.
- **原始授權**: GPL v2+
- **延伸開發**: 2025-08-20 開始基於 v1.6.2 版本進行功能擴展

## [1.6.7] - 2025-09-11

### Added
- **新增通過率欄位**: 在測試計劃統計頁面中新增通過率欄位，計算公式為：通過率 = (成功數 / (成功數 + 失敗數)) × 100%
- **合計行功能**: 在測試計劃統計頁面底部添加合計行，顯示所有測試計劃的總體統計數據
- **問題狀態顯示**: 在測試案例執行頁面中顯示關聯問題的詳細狀態信息，包括狀態、被分派者、更新時間
- **多語言支援**: 為新增的通過率欄位添加英文、日文、繁體中文翻譯

### Enhanced
- **統計頁面優化**: 改善統計頁面的顯示效果，合計行中的 "-" 符號置中顯示
- **問題關聯功能**: 優化測試案例執行與問題的關聯顯示，提供更詳細的問題信息
- **連結修復**: 修正統計頁面中測試計劃連結的 URL 生成問題

### Fixed
- **修復空白頁面**: 解決統計頁面在某些情況下顯示空白的問題
- **修復項目查找**: 修正 ApplicationsHelper 中的 find_project 方法語法錯誤
- **修復附件警告**: 暫時停用 render_attachment_warning_if_needed 以避免 NoMethodError

### Documentation
- **統計公式文件**: 創建詳細的統計計算公式文件 (doc/STATISTICS_FORMULAS.md)
- **多語言文檔**: 更新語言文件，確保所有新功能都有完整的多語言支援

## [1.6.6] - 2025-01-10

### Fixed
- **修正分頁計數錯誤**: 解決測試計劃詳細頁面中測試案例分頁顯示錯誤計數的問題（顯示 1-12/12 而非實際的 1-6/6）
- **修正 CSV 匯出重複欄位**: 解決測試計劃 CSV 匯出中出現重複的「測試案例 IDs」和「測試案例」欄位問題
- **修正測試計劃匯入失敗**: 解決測試計劃匯入時無法成功新增或更新記錄的問題，對齊 TestCaseImport 的邏輯
- **修正測試計劃連結錯誤**: 解決測試案例頁面中點擊測試計劃連結時出現「找不到專案」錯誤的問題

### Enhanced
- **查詢邏輯優化**: 改進 TestCaseQuery 中的 test_case_count 方法，使用更簡潔和準確的查詢邏輯
- **資料一致性**: 在 TestCase 模型中添加 distinct 到 with_latest_result scope，防止重複記錄
- **URL 路由修正**: 統一使用專案識別碼而非專案名稱生成 URL，確保路由正確性

## [1.6.5] - 2025-01-10

### Added
- **新增匯入功能**: 完整的 CSV 匯入系統，支援測試案例、測試計劃和測試案例執行的匯入
- **匯入流程**: 新建匯入 → 設定 → 欄位對應 → 執行匯入的完整流程
- **自動對應**: 智能的 CSV 欄位自動對應功能，支援多語系
- **匯入模板**: 提供標準化的 CSV 模板下載功能
- **匯入預覽**: 匯入前的資料預覽和驗證功能

### Enhanced
- **UI/UX 改善**: 統一所有匯入頁面的按鈕樣式和排版
- **響應式設計**: 改善表格排版，提供更緊湊和專業的視覺效果
- **錯誤處理**: 完善的錯誤處理和用戶友好的錯誤訊息
- **多語系支援**: 完整的繁體中文、英文和日文支援

### Fixed
- **檔案名稱顯示**: 修復匯入執行頁面中檔案名稱顯示空白的問題
- **ActiveRecord 物件顯示**: 修復匯入預覽中顯示 ActiveRecord 物件字串的問題
- **欄位對應**: 修復欄位對應頁面的排版和對齊問題
- **按鈕樣式**: 統一所有頁面的按鈕樣式和佈局

### Technical
- **新增模型**: Import, TestCaseImport, TestPlanImport, TestCaseExecutionImport
- **新增控制器**: ImportsController
- **新增視圖**: 完整的匯入流程視圖檔案
- **資料庫遷移**: 新增 imports 表的資料庫遷移
- **路由更新**: 新增匯入相關的路由配置

## [1.6.4] - 2025-08-20 11:40:05 CST

### Maintenance
- **延伸開發**: 基於 v1.6.2 版本進行功能擴展和改進
- **原作者致謝**: 基於 SENA Networks Inc. 的開源專案開發
- **原始作者**: 優人 岡田 (okada@sena-networks.co.jp)

### Added
- 模板下載功能：為測試案例、測試計劃和測試執行提供 CSV 模板下載
- 匯入頁面 UI 改進：新增專用的模板下載區塊和說明
- GitHub 整合：新增 Issue 和 Pull Request 模板
- 完整的權限支援：為所有角色添加測試案例管理權限

### Changed
- 更新作者資訊：Jason Liu (GitHub: @bluer1211)
- 更新 GitHub 連結：https://github.com/bluer1211/redmine-testcase-management
- 改進權限檢查邏輯：簡化模板下載的權限要求
- 優化用戶體驗：模板下載按鈕在所有相關頁面都可見

### Fixed
- 修復模板下載的 403 權限錯誤
- 修復路由名稱不匹配問題
- 修復控制器權限檢查邏輯

### Documentation
- 更新 README.md 和相關文件
- 新增 GitHub Issue 和 PR 模板
- 更新插件描述和作者資訊

### Testing
- 新增模板下載功能驗證腳本
- 完整的匯入功能測試報告

## [1.6.3] - 2024-01-15

### Improvements

* Updated to support Redmine 6.0.6
* Updated development environment setup instructions for Redmine 6.0-stable branch
* Modernized Rails 6.1 compatibility by replacing `require_dependency` with `require`
* Updated `send(:include)` to modern `include` syntax for better Rails 6.1 compatibility
* Added Traditional Chinese (zh-TW) localization support
* Updated all database migration files from Rails 5.2 to Rails 7.2.2.1 syntax for better compatibility with Redmine 6.0.6
* Fixed `acts_as_attachable` compatibility issue with Rails 7.2.2.1 by adding conditional loading

### Miscellaneous

* Updated plugin version and compatibility information

# v1.6.2

## Release v1.6.2 - 2022/12/20

### Miscellaneous

* Update plugin information about url and author_url
  promotion page should be shown as url.

# v1.6.1

## Release v1.6.1 - 2022/12/20

### Bug fixes

* Fixed db:migration error when using MariaDB/MySQL. MR#78
* Fix 500 error when this plugin is deployed for MariaDB/MySQL.
  This is just a workaround not to crash. Thus, it doesn't mean that this plugin supports MariaDB/MySQL. Note that MariaDB/MySQL support is still work-in-progress. See #8 about details.

### Miscellaneous

* Describe plugin information about author, author_url
  because SENA Networks Inc. is the stakeholder of this plugin. MR#79
* doc: Describe supported database explicitly.
* doc: Describe the procedure how to uninstall this plugin.

# v1.6.0

## Release v1.6.0 - 2022/08/09

### Improvements

* test plan/test case/test case execution: Improved to display text in left align and not to omit content. MR#76
  * test plan: Changed not to omit text case name in test plan's details.
  * test case: Changed not to omit content of test case, scenario and expected columns.
  * test case execution: Changed not to omit content of test case, scenario and expected columns.

### Bug fixes

* test plan/test case/test case execution: Fixed a bug that saving causes 500 error again.
  It was caused when the specific Redmine plugin was used with this plugin. (For example, Redmine Drive) MR#77

# v1.5.0

## Release v1.5.0 - 2022/07/20

### Improvements

* test case: Added checkbox to update existing test cases. In the previous version, if test case matches existing test case name,
 always import data as a existing test case. In this release, you can switch import mode. (By default, import as a new test case) MR#74

### Bug fixes

* Fixed a bug that saving query causes 500 error. It was caused by conflicting with other plugins (such as redmine dmsf, for example). MR#73
* test case: Fixed a missing translation for test case name in editing test case form. MR#75

### Miscellaneous

* doc: Updated CSV import specification

# v1.4.0

## Release v1.4.0 - 2022/07/05

### Improvements

* test case execution: Changed to show only date in list of test case executions for consistency. MR#62
* test case: Changed default columns in test case list. MR#63
* test case: Unified to more meaningful translation for test case label MR#64
* test plan/test case: Supported to allow overriding existing test plan/test case. MR#67,MR#68
* test case execution: Supported to specify test plan name or test case name when importing CSV. MR#71
* test case execution: Changed to export test plan name or test case name instead of id when exporting CSV. MR#72

### Bug fixes

* test case: Fixed a bug that redirect to test cases list fails when test plan is not associated with 
test case for bulk updating operation. MR#61
* test case: Fixed 500 redirect error when editing or deleting test case query. MR#65
* test case execution: Fixed to show missing statistics in sidebar. MR#66
* test plan: Fixed a bug that existing associated test cases are not reset when importing CSV with target test case id was specified. MR#70

### Miscellaneous

* doc: Added CSV import specification

# v1.3.0

## Release v1.3.0 - 2022/06/08

### Improvements

* test plan/test case: Supported to create and continue test plan/test case.

### Bug fixes

* test case: Fixed a bug that inconsistent test plan and test case
  association data cause a 500 error. This bug occurs when the following conditions are met:
  a) test_case has latest result and latest execution date
  b) there is no association with test plan and such a test case
* test plan/test case/test case execution: Fixed a bug that import button is not shown.
  This was a regression of v1.2.0.

### Miscellaneous

* doc: Described how to start a development environment

# v1.2.0

## Release v1.2.0 - 2022/05/31

In this release, permissions are re-designed.
As redmine:plugins:migrate doesn't auto migrate existing permissions,
configure roles for testcase management again.

### Improvements

* test case: Expanded scenario and expected textarea editable rows.
* test case: Changed environment input field to optional.
* test case execution: Supported to fill in issue template. MR#36
* test case: Tweaked layout for Zenmine theme.
  There was a broken floating layout issue with it. MR#35
* test case execution: Changed to show scenario and expected when editing test case. MR#38
* test case execution: Supported to filter with scenario and expected. MR#39
* test case: Supported to import with test plan CSV.
  It makes easy to import modified version of exported test case CSV. MR#41
* test case execution: Added missing filter items (test plan, test case) MR#42
* test case: Supported to filter with latest execution date/latest result. MR#46
* Translated labels for module permissions.
* test plan: Tweaked list of related test case layout in a table and
  supported bulk operations via context menu. MR#47, MR#50, MR#51, MR#52, MR#56
* Revised testcase management permissions.
  Instead of Test Cases, Test Plans, Test Case Executions, Import Test
  Cases, Import Test Plans, Import Test Case Executions, existing permissions are unified into 12 permissions.
  New permissions are: View Test Cases, Add Test Cases, Edit Test Cases, Delete Test Cases,
  View Test Plans, Add Test Plans, Edit Test Plans, Delete Test Plans,
  View Test Case Executions, Add Test Case Executions, Edit Test Case Executions, Delete Test Case Executions.
* test case: Supported bulk operations via context menu in test case list. MR#53
* test case execution: Supported bulk operations via context menu in test case execution list. MR#54
* Supported to make the "testcase management" tab highlight when it was selected.

### Bug fixes

* test case: Show newline correctly in scenario, expected fields in list.
* test case: Fixed a bug that CSV export with execution date. MR#40
* test case execution: Fixed a bug that back link navigate to list of test plan when it raised error.
  It should be linked to list of test case execution. MR#43
* Fixed a bug that non project members was listed in select options.
* Fixed a bug that "testcase management" tab was shown even though the module was deactivated for the project.
* test plan: Fixed a bug that open/closed filter causes a error. MR#44
* test case execution: Fixed a bug that empty result will be imported as "Failure" status. MR#48

### Miscellaneous

* Changed to be Redmine 4.2 ready.
* Described non supported version (4.1.0 or later is required, but not 5.0 ready)

# v1.1.0

## Release v1.1.0 - 2022/04/22

### Improvements

* test plan: Improved rendering performance to show Test Plan. #1
  Showing Test Cases associated to the Test Plan will be paginated.

### Bug fixes

* import: Fixed a bug that import fails because of detecting correct issue
* test case execution: Fixed a bug that Test Case Execution's execution date is not mandatory. #4, MR#29
* test plan stats: Fixed a bug that test case execution is counted wrongly (duplicated) #3, MR#30
* test case stats: Fixed a bug that test case execution is counted wrongly (duplicated) #3, MR#31
* Fixed a bug that issue_visibility=default is not handled correctly.
  There was a case that user can't be assigned for private project. MR#34
* test case: Fixed a bug that latest execution date is not fetched
  correctly when there are same execution date. MR#32
* CI: Fixed a bug that CI is fragile because of undetermined execution order.
* test case execution: Fixed a bug that assigned user is not shown when editing data. MR#33

# v1.0.0

## Release v1.0.0 - 2022/04/14

* Initial release
