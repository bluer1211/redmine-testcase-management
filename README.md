# Redmine Plugin Testcase Management

https://gitlab.com/clear-code/redmine-plugin-testcase-management に移動する予定のプラグインのリポジトリ


## Install

```console
$ cd /path/to/redmine/plugins
$ git clone https://gitlab.clear-code.com/clear-code/redmine-plugin-testcase-management.git testcase_management
$ cd ..
$ bundle install
$ bin/rails redmine:plugins:migrate RAILS_ENV=production
```

And then restart your Redmine.

## Tests

```console
$ cd /path/to/redmine
$ cp -r plugins/testcase_management/test/fixtures/* test/fixtures/
$ bin/rails redmine:plugins:test RAILS_ENV=test NAME=testcase_management
```
