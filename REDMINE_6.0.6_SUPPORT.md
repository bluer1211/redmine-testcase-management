# Redmine 6.0.6 支援更新

## 更新內容

### 版本更新
- 插件版本從 1.6.2 更新至 1.6.3
- 支援 Redmine 6.0.6 及以上版本
- 最後更新時間：2025年8月19日

### 主要變更

1. **版本要求更新**
   - 最低 Redmine 版本：6.0.6
   - 移除了對 Redmine 4.x 和 5.x 的明確支援說明

2. **開發環境更新**
   - 更新開發環境設置說明，使用 Redmine 6.0-stable 分支
   - 添加了 Gemfile 來確保依賴兼容性

3. **API 兼容性**
   - 檢查並確認所有 API 調用與 Rails 6.1 兼容
   - 確認 ActiveRecord 查詢語法與新版本兼容

### 安裝說明

對於 Redmine 6.0.6 的安裝，請按照以下步驟：

```bash
# 1. 進入 Redmine 插件目錄
cd /path/to/redmine/plugins

# 2. 克隆插件
git clone https://gitlab.com/redmine-plugin-testcase-management/redmine-plugin-testcase-management.git testcase_management

# 3. 返回 Redmine 根目錄
cd ..

# 4. 安裝依賴
bundle install

# 5. 運行資料庫遷移
bin/rails redmine:plugins:migrate RAILS_ENV=production

# 6. 重啟 Redmine
```

### 開發環境設置

```bash
# 1. 克隆 Redmine 6.0-stable
git clone --depth 1 --branch 6.0-stable https://github.com/redmine/redmine.git redmine

# 2. 進入 Redmine 目錄
cd redmine

# 3. 創建插件符號連結
ln -s /path/to/this/plugin plugins/testcase_management

# 4. 複製配置
cp plugins/testcase_management/config/database.yml.example.postgresql config/database.yml

# 5. 安裝依賴
bundle install

# 6. 設置資料庫
bin/rails db:create
bin/rails generate_secret_token
bin/rails db:migrate
bin/rails redmine:load_default_data REDMINE_LANG=en
bin/rails redmine:plugins:migrate

# 7. 運行測試
NAME=testcase_management PSQLRC=/tmp/nonexistent RAILS_ENV=test UI=true bin/rails redmine:plugins:test
```

### 注意事項

1. **資料庫支援**
   - PostgreSQL 12 或更高版本
   - MySQL 8 或更高版本
   - MariaDB 10.2 或更高版本

2. **權限設置**
   - 確保在專案中啟用 testcase_management 模組
   - 為每個成員角色配置適當的權限

3. **路由配置**
   - 如果遇到路由問題，請檢查 config/routes.rb 中的約束條件

### 已知限制

- 測試計劃、測試案例、測試案例執行繼承問題的權限
- 保存查詢後頁面重定向問題
- CSV 導入可能因本地化值不匹配而失敗
- 某些批量操作和上下文選單功能有限制

### 技術細節

- 使用 Rails 6.1 框架
- 保持與現有 API 的向後兼容性
- 更新了測試框架配置
- 確保所有 ActiveRecord 查詢與新版本兼容
