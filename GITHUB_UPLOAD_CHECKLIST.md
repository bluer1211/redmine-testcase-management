# GitHub 上傳檢查清單

## 📋 準備工作

### 1. 專案清理
- [ ] 移除所有備份文件 (`Gemfile.backup`, `db/backup_*/`)
- [ ] 移除臨時文件 (`*.tmp`, `*.temp`, `*.log`)
- [ ] 移除系統文件 (`.DS_Store`, `Thumbs.db`)
- [ ] 移除 IDE 文件 (`.vscode/`, `.idea/`, `*.swp`, `*.swo`)
- [ ] 移除測試覆蓋率文件 (`coverage/`, `*.coverage`)
- [ ] 移除環境文件 (`.env`, `.env.local`)
- [ ] 移除驗證腳本 (`*_validation.rb`, `update_*.rb`)

### 2. 文件更新
- [ ] 更新 README.md 中的 GitHub 連結
- [ ] 更新 CONTRIBUTING.md 中的 GitHub 連結
- [ ] 更新 SECURITY.md 中的聯繫方式
- [ ] 更新 CODE_OF_CONDUCT.md 中的聯繫方式
- [ ] 更新所有 Issue 模板中的連結
- [ ] 更新 GitHub Actions 工作流程中的連結

### 3. 版本資訊
- [ ] 確認 `init.rb` 中的版本號正確 (1.6.3)
- [ ] 確認 CHANGELOG.md 中的最新版本資訊
- [ ] 確認所有文件中的版本號一致

## 🚀 GitHub 設定

### 1. 建立新專案
- [ ] 在 GitHub 上建立新的專案
- [ ] 設定專案名稱為 `redmine-testcase-management`
- [ ] 設定專案描述
- [ ] 設定專案標籤 (tags)
- [ ] 設定專案可見性 (公開)

### 2. 專案設定
- [ ] 設定專案 About 部分
- [ ] 設定專案網站 (如果有)
- [ ] 設定專案 Wiki (如果需要)
- [ ] 設定專案 Issues
- [ ] 設定專案 Discussions
- [ ] 設定專案 Projects (如果需要)

### 3. 分支保護
- [ ] 設定 main 分支保護規則
- [ ] 要求 Pull Request 審查
- [ ] 要求狀態檢查通過
- [ ] 限制直接推送到 main 分支

## 📁 文件結構

### 1. 根目錄文件
- [ ] README.md ✅
- [ ] CHANGELOG.md ✅
- [ ] CONTRIBUTING.md ✅
- [ ] SECURITY.md ✅
- [ ] CODE_OF_CONDUCT.md ✅
- [ ] LICENSE ✅
- [ ] .gitignore ✅

### 2. GitHub 特定文件
- [ ] .github/workflows/ci.yml ✅
- [ ] .github/ISSUE_TEMPLATE/bug_report.md ✅
- [ ] .github/ISSUE_TEMPLATE/feature_request.md ✅
- [ ] .github/pull_request_template.md ✅
- [ ] .github/FUNDING.yml ✅
- [ ] .github/project-description.md ✅

### 3. 專案文件
- [ ] app/ ✅
- [ ] lib/ ✅
- [ ] config/ ✅
- [ ] db/ ✅
- [ ] test/ ✅
- [ ] doc/ ✅
- [ ] init.rb ✅

## 🔗 連結更新

### 1. 需要更新的連結
- [ ] README.md 中的安裝指令
- [ ] README.md 中的問題回報連結
- [ ] README.md 中的文件連結
- [ ] CONTRIBUTING.md 中的專案連結
- [ ] SECURITY.md 中的聯繫方式
- [ ] GitHub Actions 中的專案名稱

### 2. 範例連結格式
```markdown
https://github.com/bluer1211/redmine-testcase-management
https://github.com/bluer1211/redmine-testcase-management/issues
https://github.com/bluer1211/redmine-testcase-management/discussions
https://github.com/bluer1211/redmine-testcase-management/wiki
```

## 🚀 上傳步驟

### 1. 初始化 Git 專案
```bash
cd redmine/plugins/testcase_management
git init
git add .
git commit -m "Initial commit: Redmine Testcase Management Plugin v1.6.3"
```

### 2. 添加遠端倉庫
```bash
git remote add origin https://github.com/bluer1211/redmine-testcase-management.git
```

### 3. 推送到 GitHub
```bash
git branch -M main
git push -u origin main
```

### 4. 建立 Release
- [ ] 在 GitHub 上建立 Release
- [ ] 標籤版本為 `v1.6.3`
- [ ] 添加 Release 說明
- [ ] 上傳任何相關的發布文件

## 📊 後續工作

### 1. 專案推廣
- [ ] 在 Redmine 社群論壇發布
- [ ] 在相關技術部落格分享
- [ ] 在社交媒體宣傳
- [ ] 添加到 Redmine 插件目錄

### 2. 社群管理
- [ ] 回應 Issues 和 Pull Requests
- [ ] 維護專案文件
- [ ] 定期更新依賴
- [ ] 處理安全問題

### 3. 持續改進
- [ ] 收集使用者反饋
- [ ] 規劃新功能
- [ ] 改善程式碼品質
- [ ] 擴展測試覆蓋率

## ✅ 最終檢查

### 1. 功能檢查
- [ ] 所有測試通過
- [ ] 安裝程序正常
- [ ] 基本功能運作正常
- [ ] 文件完整且準確

### 2. 品質檢查
- [ ] 程式碼風格一致
- [ ] 沒有安全漏洞
- [ ] 效能表現良好
- [ ] 使用者體驗良好

### 3. 文件檢查
- [ ] README.md 清晰易懂
- [ ] 安裝指南完整
- [ ] 貢獻指南詳細
- [ ] 所有連結有效

---

**注意**: 所有連結已更新為您的 GitHub 使用者名稱 `bluer1211`。
