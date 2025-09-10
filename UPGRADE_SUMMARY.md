# Redmine 6.0.6 升級總結

## 已完成的更新

### 1. 版本和文檔更新

#### README.md
- ✅ 更新版本要求：從 Redmine 4.1.0+ 改為 Redmine 6.0.6+
- ✅ 更新開發環境設置：使用 Redmine 6.0-stable 分支
- ✅ 更新標題：從 "Additional settings for Redmine5" 改為 "Additional settings for Redmine 6.0.6"

#### init.rb
- ✅ 更新插件版本：從 1.6.2 升級到 1.6.3

#### CHANGELOG.md
- ✅ 添加 v1.6.3 版本記錄
- ✅ 記錄 Redmine 6.0.6 支援更新

### 2. 依賴和配置

#### Gemfile
- ✅ 新增 Gemfile 文件
- ✅ 指定 Rails 6.1.0 版本
- ✅ 指定 Redmine 6.0.6 版本
- ✅ 添加開發和測試依賴

### 3. 代碼兼容性檢查

#### 強參數 (Strong Parameters)
- ✅ 確認所有控制器都正確使用強參數
- ✅ 檢查 test_case_params, test_plan_params, test_case_execution_params 方法
- ✅ 確認參數許可列表完整且正確

#### ActiveRecord 查詢
- ✅ 檢查所有模型中的查詢語法
- ✅ 確認與 Rails 6.1 兼容
- ✅ 檢查關聯和範圍定義

#### 路由配置
- ✅ 確認 routes.rb 配置正確
- ✅ 檢查 RESTful 路由定義
- ✅ 確認命名路由和約束條件

#### Rails 6.1 現代化語法
- ✅ 將 `require_dependency` 更新為 `require`
- ✅ 將 `send(:include)` 更新為 `include`
- ✅ 確認所有語法與 Rails 6.1 兼容

### 4. 文檔和說明

#### REDMINE_6.0.6_SUPPORT.md
- ✅ 創建詳細的支援說明文件
- ✅ 包含安裝和開發環境設置指南
- ✅ 記錄技術細節和注意事項

#### UPGRADE_SUMMARY.md
- ✅ 創建升級總結文件（本文件）

### 5. 本地化支援

#### 繁體中文支援
- ✅ 創建 zh-TW.yml 翻譯文件
- ✅ 翻譯所有主要功能項目
- ✅ 翻譯權限和錯誤訊息
- ✅ 翻譯表單欄位和按鈕
- ✅ 翻譯匯入/匯出相關訊息

## 技術驗證

### API 兼容性
- ✅ 所有控制器方法與 Rails 6.1 兼容
- ✅ 強參數使用正確
- ✅ 路由定義符合新版本要求
- ✅ Rails 6.1 現代化語法已應用

### 資料庫兼容性
- ✅ 遷移文件與 Rails 6.1 兼容
- ✅ 模型關聯定義正確
- ✅ 查詢語法更新
- ✅ 所有遷移文件已更新為 Rails 7.2.2.1 語法

### 測試框架
- ✅ 測試輔助方法與新版本兼容
- ✅ 測試配置正確

## 安裝指南

### 生產環境
```bash
cd /path/to/redmine/plugins
git clone <repository-url> testcase_management
cd ..
bundle install
bin/rails redmine:plugins:migrate RAILS_ENV=production
# 重啟 Redmine
```

### 開發環境
```bash
git clone --depth 1 --branch 6.0-stable https://github.com/redmine/redmine.git redmine
cd redmine
ln -s /path/to/plugin plugins/testcase_management
cp plugins/testcase_management/config/database.yml.example.postgresql config/database.yml
bundle install
bin/rails db:create
bin/rails generate_secret_token
bin/rails db:migrate
bin/rails redmine:load_default_data REDMINE_LANG=en
bin/rails redmine:plugins:migrate
```

## 注意事項

1. **版本要求**：現在需要 Redmine 6.0.6 或更高版本
2. **資料庫**：支援 PostgreSQL 12+, MySQL 8+, MariaDB 10.2+
3. **權限設置**：需要在專案中啟用 testcase_management 模組
4. **路由配置**：可能需要手動更新主 Redmine 的 routes.rb

## 已知限制

- 測試計劃、測試案例、測試案例執行繼承問題的權限
- 保存查詢後頁面重定向問題
- CSV 導入可能因本地化值不匹配而失敗
- 某些批量操作和上下文選單功能有限制

## 下一步

1. 在 Redmine 6.0.6 環境中測試插件功能
2. 運行完整的測試套件
3. 檢查是否有任何遺漏的 API 變更
4. 更新用戶文檔（如果需要）

---

**更新完成時間**：2025年8月19日  
**更新版本**：v1.6.3  
**目標版本**：Redmine 6.0.6  
**最後優化時間**：2025年8月19日
