# v1.4.0

## Release v1.4.0 - 2022/07/DD

### Improvements

* test case execution: Changed to show only date in list of test case executions for consistency. MR#62
* test case: Changed default columns in test case list. MR#63
* test case: Unified to more meaningful translation for test case label MR#64
* test plan/test case: Supported to allow overriding existing test plan/test case. MR#67,MR#68
* test case execution: Supported to specify test plan name or test case name when importing CSV. MR#71

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
