# 貢獻指南

感謝您對 Redmine Testcase Management Plugin 的關注！我們歡迎所有形式的貢獻。

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

3. **設定 Redmine**
   ```bash
   cp config/database.yml.example.postgresql config/database.yml
   bin/rails db:create db:migrate
   bin/rails redmine:load_default_data REDMINE_LANG=en
   ```

4. **執行測試**
   ```bash
   bin/rails redmine:plugins:test RAILS_ENV=test NAME=testcase_management
   ```

## 📋 程式碼風格

### Ruby 程式碼

- 遵循 [Ruby Style Guide](https://github.com/rubocop/ruby-style-guide)
- 使用 2 個空格縮排
- 行長度限制在 80 字元內
- 使用有意義的變數和方法名稱

### ERB 模板

- 使用適當的縮排
- 避免在模板中放置複雜的邏輯
- 使用輔助方法處理複雜的顯示邏輯

### JavaScript

- 使用 ES6+ 語法
- 遵循 [Airbnb JavaScript Style Guide](https://github.com/airbnb/javascript)
- 使用有意義的變數名稱

## 🌐 國際化 (i18n)

### 添加新語言

1. 在 `config/locales/` 目錄下創建新的語言文件
2. 翻譯所有必要的鍵值
3. 更新 `init.rb` 中的語言設定

### 翻譯指南

- 保持翻譯的一致性
- 使用適當的敬語
- 考慮文化差異

## 📚 文件更新

當您添加新功能或修改現有功能時，請：

1. 更新 README.md（如果需要）
2. 更新 CHANGELOG.md
3. 更新相關的 Wiki 頁面
4. 添加或更新 API 文件

## 🔍 審查流程

1. **自動檢查**
   - CI/CD 管道會自動執行測試
   - 檢查程式碼風格
   - 驗證文件格式

2. **人工審查**
   - 至少需要一位維護者的批准
   - 審查程式碼品質和安全性
   - 檢查測試覆蓋率

3. **合併**
   - 通過所有檢查後合併到主分支
   - 自動發布新版本（如果適用）

## 🏷️ 版本發布

### 版本號規範

我們使用 [Semantic Versioning](https://semver.org/)：

- `MAJOR.MINOR.PATCH`
- MAJOR：不相容的 API 變更
- MINOR：向後相容的新功能
- PATCH：向後相容的錯誤修復

### 發布流程

1. 更新版本號
2. 更新 CHANGELOG.md
3. 創建 Release Tag
4. 發布到 GitHub Releases

## 🤝 行為準則

我們致力於提供一個友善和包容的環境：

- 尊重所有貢獻者
- 使用包容性語言
- 接受建設性批評
- 專注於問題而非個人

## 📞 聯繫方式

如果您有任何問題或需要幫助：

- 📧 電子郵件：[bluer1211@gmail.com](mailto:bluer1211@gmail.com)
- 💬 討論：[GitHub Discussions](https://github.com/bluer1211/redmine-testcase-management/discussions)
- 🐛 問題：[GitHub Issues](https://github.com/bluer1211/redmine-testcase-management/issues)

---

再次感謝您的貢獻！您的努力讓這個專案變得更好。🎉
