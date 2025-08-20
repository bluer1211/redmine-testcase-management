# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.6.4] - 2025-08-20 11:40:05 CST

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
