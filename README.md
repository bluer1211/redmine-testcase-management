# Redmine Plugin Testcase Management

https://gitlab.com/redmine-plugin-testcase-management/redmine-plugin-testcase-management

## Requirements

* Redmine 4.1.0 or later (not Redmine 5.x)
  * TimestampQueryColumn was implemented since 4.1.0.
* PostgreSQL

## Install

```console
$ cd /path/to/redmine/plugins
$ git clone https://gitlab.com/redmine-plugin-testcase-management/redmine-plugin-testcase-management.git testcase_management
$ cd ..
$ bundle install
$ bin/rails redmine:plugins:migrate RAILS_ENV=production
```

And then restart your Redmine.

## Settings

Not only enabling testcase management module in each project, you need to configure appropriate permissions
for every member roles.

Since v1.2.0, the following 12 permissions were introduced:

* View Test Plans
* Add Test Plans
* Edit Test Plans
* Delete Test Plans
* Add Test Cases
* Edit Test Cases
* Delete Test Cases
* View Test Case Executions
* Add Test Case Executions
* Edit Test Case Executions
* Delete Test Case Executions

NOTE: As plugin inherits issue's permissions, issue's corresponding permissions also must be enabled.
Thus, if you want to edit test plan, enable both of "Edit Test Plans", "Edit issues" permissions for role.

Up to v1.1.0, the following 3 permissions were used (now deprecated, and removed)

* Import Test Cases
* Import Test Plans
* Import Test Case Executions

## Known Restrictions

* Test Plan, Test Case, Test Case Execution inherits permission from issues. (view, edit, and so on)
* After saving query, the page will not be redirected to the page which filter was executed. (Always redirected to test case list)
* CSV import may fails when the localized value of column is not matched to stored in database.
* ~~Enabled/Disabled plugin status is not reflected in main menu.~~ (Fixed in 1.2.0)
* test plans: Context menu operation for listed test plans supports only editing test plan, changing user, changing status and delete test plans.
* test plans: Bulk update for listed test plans supports only changing user, status, begin date, end date.
* test plan: Context menu operation for related test cases supports only editing test case, changing user, deleting related test cases.
* test plan: Bulk update for related test cases supports only changing environment, user.
* test cases: Context menu operation for listed test case supports only editing test case, changing user, delete test cases.
* test cases: Bulk update for listed test cases supports only changing user, status, begin date, end date.
* test case: Context menu operation for listed test case executions is not supported.
* test case: Bulk update for listed test case executions is not supported
* test case executions: Context menu operation for listed test case executions supports only editing test case execution, changing user, changing result and deleting test case executions.
* test case executions: Bulk update for listed test case executions supports only changing user, changing execution date.
* Not only "View issues" permission, "Add issues", "Edit Issues", "Delete Issues" permissions were also required for
  each adding/editing/deleting actions in testcase management.
  In the future, this restriction will be changed to require only "View issues" about issue permission. (Delegate permission control in plugin's side)

## Tests

```console
$ cd /path/to/redmine
$ cp -r plugins/testcase_management/test/fixtures/* test/fixtures/
$ bin/rails redmine:plugins:test RAILS_ENV=test NAME=testcase_management
```
## License

GPL v2 or later. (same as Redmine)
