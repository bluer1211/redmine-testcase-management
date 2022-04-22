# Redmine Plugin Testcase Management

https://gitlab.com/clear-code/redmine-plugin-testcase-management

## Install

```console
$ cd /path/to/redmine/plugins
$ git clone https://gitlab.clear-code.com/clear-code/redmine-plugin-testcase-management.git testcase_management
$ cd ..
$ bundle install
$ bin/rails redmine:plugins:migrate RAILS_ENV=production
```

And then restart your Redmine.

## Known Restrictions

* Test Plan, Test Case, Test Case Execution inherits permission from issues. (view, edit, and so on)
* After saving query, the page will not be redirected to the page which filter was executed. (Always redirected to test case list)
* Test Plan, Test Case, Test Case Execution inherits permission from issues. (view, edit, and so on)
* CSV import may fails when the localized value of column is not matched to stored in database.
* Enabled/Disabled plugin status is not reflected in main menu.

## Tests

```console
$ cd /path/to/redmine
$ cp -r plugins/testcase_management/test/fixtures/* test/fixtures/
$ bin/rails redmine:plugins:test RAILS_ENV=test NAME=testcase_management
```
## License

GPL v2 or later. (same as Redmine)
