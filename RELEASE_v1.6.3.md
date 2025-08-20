# Release v1.6.3

## 🎉 重要更新

這是 Redmine Testcase Management Plugin 的重要更新版本，支援最新的 Redmine 6.0.6 和 Rails 7.2.2.1。

## 📋 版本資訊

- **版本**: v1.6.3
- **發布日期**: 2025年1月
- **Redmine 支援**: 6.0.6+
- **Rails 支援**: 7.2.2.1+
- **資料庫支援**: PostgreSQL 12+, MySQL 8+, MariaDB 10.2+

## ✨ 主要改進

### 🔧 技術升級
- **Redmine 6.0.6 支援**: 完全相容最新的 Redmine 版本
- **Rails 7.2.2.1 支援**: 升級到最新的 Rails 框架
- **現代化語法**: 將 `require_dependency` 替換為 `require`
- **相容性修復**: 修復 `acts_as_attachable` 與 Rails 7.2.2.1 的相容性問題

### 🌐 國際化
- **繁體中文支援**: 新增完整的繁體中文 (zh-TW) 本地化支援
- **語言檔案**: 包含完整的介面翻譯

### 🗄️ 資料庫
- **遷移檔案更新**: 所有資料庫遷移檔案從 Rails 5.2 升級到 Rails 7.2.2.1 語法
- **相容性提升**: 更好的 Redmine 6.0.6 相容性

### 📚 文件改進
- **開發環境設定**: 更新 Redmine 6.0-stable 分支的開發環境設定說明
- **版本資訊**: 更新插件版本和相容性資訊

## 🚀 安裝指南

### 快速安裝

```bash
cd /path/to/redmine/plugins
git clone https://github.com/bluer1211/redmine-testcase-management.git testcase_management
cd ..
bundle install
bin/rails redmine:plugins:migrate RAILS_ENV=production
```

### Redmine 6.0.6 額外設定

由於 Redmine 6.0.6 的路由限制，需要手動修改 `config/routes.rb` 文件：

找到以下行：
```ruby
constraints object_type: /(issues|versions|news|messages|wiki_pages|projects|documents|journals)/ do
```

修改為：
```ruby
constraints object_type: /(issues|versions|news|messages|wiki_pages|projects|documents|journals|test_cases|test_case_executions)/ do
```

## 🔧 系統需求

- **Redmine**: 6.0.6 或更新版本
- **PostgreSQL**: 12 或更新版本
- **MySQL**: 8 或更新版本
- **MariaDB**: 10.2 或更新版本

## 🛡️ 安全性

- 修復了多個安全性問題
- 更新了相依套件
- 改善了錯誤處理

## 🐛 已知問題

- MySQL 和 MariaDB 支援仍在開發中 (#8)
- 某些第三方插件可能會有相容性問題

## 📞 支援

如果您遇到任何問題，請：

- 📧 電子郵件：[bluer1211@gmail.com](mailto:bluer1211@gmail.com)
- 🐛 問題回報：[GitHub Issues](https://github.com/bluer1211/redmine-testcase-management/issues)
- 📖 文件：[GitHub Wiki](https://github.com/bluer1211/redmine-testcase-management/wiki)

## 🤝 貢獻

我們歡迎所有形式的貢獻！請參閱 [CONTRIBUTING.md](CONTRIBUTING.md) 了解詳細的貢獻指南。

## 📄 授權

此專案採用 GPL v2 或更新版本授權 - 詳見 [LICENSE](LICENSE) 文件。

## 👥 致謝

感謝所有貢獻者和使用者對這個專案的支持！

---

**下載**: [v1.6.3](https://github.com/bluer1211/redmine-testcase-management/releases/tag/v1.6.3)
