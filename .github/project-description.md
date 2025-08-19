# Redmine Testcase Management Plugin

一個功能完整的 Redmine 測試案例管理插件，支援測試計劃、測試案例和測試執行結果的管理。

## 主要功能

- 📋 測試計劃管理
- 🧪 測試案例管理  
- ✅ 測試執行追蹤
- 📊 統計報表
- 📥 CSV 匯入/匯出
- 🔍 進階查詢
- 🌐 多語言支援

## 技術規格

- **Redmine**: 6.0.6+
- **Rails**: 7.2.2.1+
- **資料庫**: PostgreSQL 12+, MySQL 8+, MariaDB 10.2+
- **授權**: GPL v2+

## 快速開始

```bash
cd /path/to/redmine/plugins
git clone https://github.com/bluer1211/redmine-testcase-management.git testcase_management
cd ..
bundle install
bin/rails redmine:plugins:migrate RAILS_ENV=production
```

## 文件

- 📖 [安裝指南](README.md#安裝指南)
- 🔧 [開發設定](README.md#開發環境設定)
- 🤝 [貢獻指南](CONTRIBUTING.md)
- 🛡️ [安全政策](SECURITY.md)

## 社群

- 🐛 [問題回報](https://github.com/bluer1211/redmine-testcase-management/issues)
- 💬 [討論](https://github.com/bluer1211/redmine-testcase-management/discussions)
- 📧 [聯繫我們](mailto:bluer1211@gmail.com)

## 授權

此專案採用 GPL v2 或更新版本授權 - 詳見 [LICENSE](LICENSE) 文件。
