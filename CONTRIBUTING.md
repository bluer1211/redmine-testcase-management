# 貢獻指南

## 原作者致謝

本插件基於 SENA Networks Inc. 的開源專案進行延伸開發。

- **原始作者**: 優人 岡田 (okada@sena-networks.co.jp)
- **原始公司**: SENA Networks Inc.
- **原始授權**: GPL v2+
- **延伸開發**: 基於 v1.6.2 版本進行功能擴展和改進

感謝您對 Redmine Testcase Management Plugin 的貢獻！我們歡迎所有形式的貢獻，包括但不限於：

- 🐛 回報 Bug
- 💡 功能建議
- 📝 文件改進
- 🔧 程式碼優化
- 🌐 翻譯貢獻

## 🚀 如何貢獻

### 回報問題

如果您發現了問題或有功能建議，請：

1. 檢查 [Issues](https://github.com/bluer1211/redmine-testcase-management/issues) 是否已經存在
2. 如果不存在，請創建新的 Issue
3. 使用清晰的標題描述問題
4. 提供詳細的步驟重現問題
5. 包含您的環境資訊（Redmine 版本、資料庫類型等）

### 提交 Pull Request

1. **Fork 專案**
   ```bash
   git clone https://github.com/bluer1211/redmine-testcase-management.git
   cd redmine-testcase-management
   ```

2. **建立功能分支**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **進行變更**
   - 遵循現有的程式碼風格
   - 添加必要的測試
   - 更新相關文件

4. **提交變更**
   ```bash
   git add .
   git commit -m "feat: add new feature description"
   ```

5. **推送到分支**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **開啟 Pull Request**
   - 提供清晰的描述
   - 連結相關的 Issue
   - 等待審查

## 📝 提交訊息規範

我們使用 [Conventional Commits](https://www.conventionalcommits.org/) 規範：

- `feat:` - 新功能
- `fix:` - 錯誤修復
- `docs:` - 文件更新
- `style:` - 程式碼格式調整
- `refactor:` - 程式碼重構
- `test:` - 測試相關
- `chore:` - 建置過程或輔助工具的變動

範例：
```
feat: add CSV export functionality for test cases
fix: resolve permission issue in test plan creation
docs: update installation instructions for Redmine 6.0.6
```

## 🧪 測試指南

### 執行測試

```bash
cd /path/to/redmine
cp -r plugins/testcase_management/test/fixtures/* test/fixtures/
bin/rails redmine:plugins:test RAILS_ENV=test NAME=testcase_management
```

### 測試覆蓋率

確保您的變更包含適當的測試覆蓋率：

- 單元測試：測試模型和輔助方法
- 功能測試：測試控制器動作
- 整合測試：測試完整的工作流程
- 系統測試：測試使用者介面

## 🔧 開發環境設定

### 前置需求

- Ruby 3.0+
- PostgreSQL 12+
- Docker (可選)
- geckodriver (系統測試用)

### 快速開始

1. **設定資料庫**
   ```bash
   docker-compose -f db/docker-compose.yml up -d
   ```

2. **安裝依賴**
   ```bash
   bundle install
   ```