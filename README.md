# Redmine Plugin Testcase Management

一個功能完整的 Redmine 測試案例管理插件，支援測試計劃、測試案例和測試執行的完整生命週期管理。

## 🌟 主要功能

- **測試計劃管理** - 創建、編輯、刪除測試計劃
- **測試案例管理** - 完整的測試案例 CRUD 操作
- **測試執行追蹤** - 記錄和管理測試執行結果
- **統計報表** - 提供測試相關的統計數據
- **匯入/匯出功能** - 支援 CSV 格式的數據匯入匯出
- **多語言支援** - 支援英文、日文、繁體中文

## 📋 系統需求

* **Redmine**: 4.1.0 或更高版本（也相容於 Series 5）
  * TimestampQueryColumn 自 4.1.0 版本開始實作
* **資料庫**:
  * PostgreSQL 12 或更高版本
  * MySQL 8 或更高版本
  * MariaDB 10.2 或更高版本
* **Ruby**: 2.7 或更高版本
* **Rails**: 5.2 或更高版本

## 🚀 安裝指南

### 安裝到現有的 Redmine 實例

```bash
# 1. 進入 Redmine 插件目錄
cd /path/to/redmine/plugins

# 2. 克隆插件
git clone https://github.com/your-username/redmine-plugin-testcase-management.git testcase_management

# 3. 返回 Redmine 根目錄
cd ..

# 4. 安裝依賴
bundle install

# 5. 執行資料庫遷移
bin/rails redmine:plugins:migrate RAILS_ENV=production

# 6. 重啟 Redmine 服務
```

### 使用 Docker 安裝

```bash
# 1. 克隆插件到 plugins 目錄
git clone https://github.com/your-username/redmine-plugin-testcase-management.git redmine/plugins/testcase_management

# 2. 重啟 Docker 容器
docker-compose restart
```

### Additional settings for Redmine5

* There is a problem with the image link, please correct it by typing directly

There is a condition that must be entered, which exists in config/routes.rb.
```routes.rb.
315  constraints object_type: /(issues|versions|news|messages|wiki_pages|projects|documents|journals)/ do
```
Please add the following conditions in these brackets
```
|test_cases|test_case_executions
```
Restart Redmine afterwards.

## Uninstall from an existing redmine instance

As this plugin does not support `bundle exec rake redmine:plugins:migrate with VERSION=0` because of
irreversible migration, you need to manually execute the following instruction.

1. Drop related tables from database

First, connect your Redmine database, then execute drop queries.

```console
DROP TABLE test_plans CASCADE;
DROP TABLE test_cases CASCADE;
DROP TABLE test_case_executions;
DROP TABLE test_case_test_plans;
```

2, Remove plugins/testcase_management

```console
$ rm -fr plugins/testcase_management
```

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
* MySQL and MariaDB is not supported yet. #8

## For Developers

Initially you need to setup Docker to run withotu root privilege.
For example, if you running Ubuntu 21.04:

```console
$ sudo apt install git docker-compose uidmap
$ sudo adduser $USER docker
(logout and login)
$ newgrp docker
```

For more details, see instructions: https://docs.docker.com/engine/install/linux-postinstall/

And you also need to install geckodriver for system testing. For example:

```console
$ wget https://github.com/mozilla/geckodriver/releases/download/v0.30.0/geckodriver-v0.30.0-linux64.tar.gz
$ tar xf geckodriver-v0.30.0-linux64.tar.gz
$ sudo mv geckodriver /usr/local/bin
```

While devlopment you should run a PostgreSQL container as the DB:

```console
$ git clone https://gitlab.com/redmine-plugin-testcase-management/redmine-plugin-testcase-management.git
$ cd redmine-plugin-testcase-management
$ docker-compose -f db/docker-compose.yml up
```

Now you are ready to setup development environment Redmine. In another shell session, run following:

```console
$ sudo apt install bundler ruby-dev libpq-dev build-essential
$ git clone \
    --depth 1 \
    --branch 4.2-stable \
    https://github.com/redmine/redmine.git \
    redmine
$ cd redmine
$ ln -s /path/to/cloned/this/repository plugins/testcase_management
$ cp plugins/testcase_management/config/database.yml.example.postgresql config/database.yml
$ cp plugins/testcase_management/test/fixtures/*.yml test/fixtures/
$ cp plugins/testcase_management/test/fixtures/files/*.csv test/fixtures/files/
$ bundle install
$ bin/rails db:create
$ bin/rails generate_secret_token
$ bin/rails db:migrate
$ bin/rails redmine:load_default_data REDMINE_LANG=en
$ bin/rails redmine:plugins:migrate
$ NAME=testcase_management PSQLRC=/tmp/nonexistent RAILS_ENV=test UI=true bin/rails redmine:plugins:test
```

All tests should pass. If you see failure or errored tests, please contribute to fix them.


## Tests

```console
$ cd /path/to/redmine
$ cp -r plugins/testcase_management/test/fixtures/* test/fixtures/
$ bin/rails redmine:plugins:test RAILS_ENV=test NAME=testcase_management
```
## License

GPL v2 or later. (same as Redmine)
