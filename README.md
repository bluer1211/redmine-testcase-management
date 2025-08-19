# Redmine Testcase Management Plugin

[![Redmine Version](https://img.shields.io/badge/Redmine-6.0.6+-red.svg)](https://redmine.org)
[![Rails Version](https://img.shields.io/badge/Rails-7.2.2.1+-green.svg)](https://rubyonrails.org)
[![License](https://img.shields.io/badge/License-GPL%20v2%2B-blue.svg)](LICENSE)
[![Plugin Version](https://img.shields.io/badge/Version-1.6.3-orange.svg)](CHANGELOG.md)

一個功能完整的 Redmine 測試案例管理插件，支援測試計劃、測試案例和測試執行結果的管理。

## ✨ 功能特色

- 📋 **測試計劃管理** - 創建和管理測試計劃
- 🧪 **測試案例管理** - 詳細的測試案例設計和維護
- ✅ **測試執行追蹤** - 記錄和追蹤測試執行結果
- 📊 **統計報表** - 提供測試覆蓋率和執行統計
- 📥 **CSV 匯入/匯出** - 支援大量資料的批次處理
- 🔍 **進階查詢** - 強大的篩選和搜尋功能
- 🌐 **多語言支援** - 支援英文、日文和繁體中文

## 📋 系統需求

- **Redmine**: 6.0.6 或更新版本
- **PostgreSQL**: 12 或更新版本
- **MySQL**: 8 或更新版本  
- **MariaDB**: 10.2 或更新版本

## 🚀 安裝指南

### 1. 下載插件

```bash
cd /path/to/redmine/plugins
git clone https://github.com/bluer1211/redmine-testcase-management.git testcase_management
```

### 2. 安裝依賴

```bash
cd /path/to/redmine
bundle install
```

### 3. 執行資料庫遷移

```bash
bin/rails redmine:plugins:migrate RAILS_ENV=production
```

### 4. 重啟 Redmine

```bash
# 重啟您的 Redmine 服務
```

### 5. Redmine 6.0.6 額外設定

由於 Redmine 6.0.6 的路由限制，需要手動修改 `config/routes.rb` 文件：

找到以下行：
```ruby
constraints object_type: /(issues|versions|news|messages|wiki_pages|projects|documents|journals)/ do
```

修改為：
```ruby
constraints object_type: /(issues|versions|news|messages|wiki_pages|projects|documents|journals|test_cases|test_case_executions)/ do
```

修改後重啟 Redmine。

## ⚙️ 權限設定

插件提供以下 12 個權限，需要在專案角色中進行配置：

### 測試計劃權限
- **查看測試計劃** (View Test Plans)
- **新增測試計劃** (Add Test Plans)  
- **編輯測試計劃** (Edit Test Plans)
- **刪除測試計劃** (Delete Test Plans)

### 測試案例權限
- **查看測試案例** (View Test Cases)
- **新增測試案例** (Add Test Cases)
- **編輯測試案例** (Edit Test Cases)
- **刪除測試案例** (Delete Test Cases)

### 測試執行權限
- **查看測試執行** (View Test Case Executions)
- **新增測試執行** (Add Test Case Executions)
- **編輯測試執行** (Edit Test Case Executions)
- **刪除測試執行** (Delete Test Case Executions)

> **注意**: 由於插件繼承了 Issue 的權限，相應的 Issue 權限也必須啟用。例如，要編輯測試計劃，需要同時啟用「編輯測試計劃」和「編輯問題」權限。

## 🗑️ 解除安裝

由於此插件不支援可逆遷移，需要手動執行以下步驟：

### 1. 刪除資料庫表格

連接到您的 Redmine 資料庫，執行以下 SQL：

```sql
DROP TABLE test_plans CASCADE;
DROP TABLE test_cases CASCADE;
DROP TABLE test_case_executions;
DROP TABLE test_case_test_plans;
```

### 2. 移除插件目錄

```bash
rm -fr plugins/testcase_management
```

## 🧪 開發環境設定

### 前置需求

1. **Docker 設定** (Ubuntu 21.04 範例)：
```bash
sudo apt install git docker-compose uidmap
sudo adduser $USER docker
# 登出並重新登入
newgrp docker
```

2. **安裝 geckodriver**：
```bash
wget https://github.com/mozilla/geckodriver/releases/download/v0.30.0/geckodriver-v0.30.0-linux64.tar.gz
tar xf geckodriver-v0.30.0-linux64.tar.gz
sudo mv geckodriver /usr/local/bin
```

### 開發環境建立

1. **啟動 PostgreSQL 容器**：
```bash
git clone https://github.com/your-username/redmine-testcase-management.git
cd redmine-testcase-management
docker-compose -f db/docker-compose.yml up
```

2. **設定 Redmine 開發環境**：
```bash
sudo apt install bundler ruby-dev libpq-dev build-essential
git clone --depth 1 --branch 6.0-stable https://github.com/redmine/redmine.git redmine
cd redmine
ln -s /path/to/cloned/this/repository plugins/testcase_management
cp plugins/testcase_management/config/database.yml.example.postgresql config/database.yml
cp plugins/testcase_management/test/fixtures/*.yml test/fixtures/
cp plugins/testcase_management/test/fixtures/files/*.csv test/fixtures/files/
bundle install
bin/rails db:create
bin/rails generate_secret_token
bin/rails db:migrate
bin/rails redmine:load_default_data REDMINE_LANG=en
bin/rails redmine:plugins:migrate
NAME=testcase_management PSQLRC=/tmp/nonexistent RAILS_ENV=test UI=true bin/rails redmine:plugins:test
```

## 🧪 執行測試

```bash
cd /path/to/redmine
cp -r plugins/testcase_management/test/fixtures/* test/fixtures/
bin/rails redmine:plugins:test RAILS_ENV=test NAME=testcase_management
```

## 📝 已知限制

- 測試計劃、測試案例、測試執行繼承 Issue 的權限
- 儲存查詢後，頁面會重新導向到測試案例列表
- CSV 匯入可能因本地化值與資料庫儲存值不匹配而失敗
- 測試計劃的右鍵選單操作僅支援編輯、變更使用者、變更狀態和刪除
- 測試案例的右鍵選單操作僅支援編輯、變更使用者和刪除
- 測試執行的右鍵選單操作僅支援編輯、變更使用者、變更結果和刪除
- MySQL 和 MariaDB 支援仍在開發中 (#8)

## 🤝 貢獻指南

我們歡迎所有形式的貢獻！請參閱 [CONTRIBUTING.md](CONTRIBUTING.md) 了解詳細的貢獻指南。

### 回報問題

如果您發現任何問題，請在 [GitHub Issues](https://github.com/bluer1211/redmine-testcase-management/issues) 中回報。

### 提交 Pull Request

1. Fork 此專案
2. 建立您的功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的變更 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 開啟 Pull Request

## 📄 授權

此專案採用 GPL v2 或更新版本授權 - 詳見 [LICENSE](LICENSE) 文件。

## 👥 作者

* **Kentaro Hayashi** - *初始開發* - [ClearCode Inc.](https://github.com/clear-code)
* **優人 岡田** - *貢獻者* - [Sena Networks](https://sena-networks.co.jp)

## 🤝 貢獻者

* **Jason Liu** - *Redmine 6.0.6 & Rails 7.2.2.1 升級* - [bluer1211@gmail.com](mailto:bluer1211@gmail.com)

## 📞 支援

- 📧 電子郵件：[bluer1211@gmail.com](mailto:bluer1211@gmail.com)
- 🐛 問題回報：[GitHub Issues](https://github.com/bluer1211/redmine-testcase-management/issues)
- 📖 文件：[Wiki](https://github.com/bluer1211/redmine-testcase-management/wiki)

## 📈 更新日誌

詳見 [CHANGELOG.md](CHANGELOG.md) 了解完整的更新歷史。

---

⭐ 如果這個專案對您有幫助，請給我們一個星標！
