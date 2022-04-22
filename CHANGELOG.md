# v1.1.0

## Release v1.1.0 - 2022/04/22

### Improvements

* test plan: Improved rendering performance to show Test Plan.
  Showing Test Cases associated to the Test Plan will be paginated.

### Bug fixes

* import: Fixed a bug that import fails because of detecting correct issue
* test case execution: Fixed a bug that Test Case Execution's execution date is not mandatory. MR#29
* test plan stats: Fixed a bug that test case execution is counted wrongly (duplicated) MR#30
* test case stats: Fixed a bug that test case execution is counted wrongly (duplicated) MR#31
* Fixed a bug that issue_visibility=default is not handled correctly.
  There was a case that user can't be assigned for private project. MR#34
* test case: Fixed a bug that latest execution date is not fetched
  correctly when there are same execution date. MR#32
* CI: Fixed a bug that CI is fragile because of undetermined execution order.
* test case execution: Fixed a bug that assigned user is not shown when editing data. MR#33

# v1.0.0

## Release v1.0.0 - 2022/04/14

* Initial release
