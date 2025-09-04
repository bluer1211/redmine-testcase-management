# Git 版本管理指南

## 📋 當前狀態

### 最新提交
- **提交 ID**: `6cdf3dc`
- **標籤**: `v1.0.0-fixed`
- **描述**: 修復所有匯入功能和統計頁面連結問題

### 修復內容摘要
1. ✅ 所有三個匯入模板的專案上下文修復
2. ✅ 附件功能修復
3. ✅ 統計頁面連結修復
4. ✅ 路由配置修復
5. ✅ 新增自定義匯入控制器

## 🔄 常用 Git 操作

### 查看當前狀態
```bash
git status
```

### 查看提交歷史
```bash
git log --oneline -10
```

### 查看所有標籤
```bash
git tag -l
```

### 回滾到修復版本
```bash
# 回滾到修復版本標籤
git checkout v1.0.0-fixed

# 或者回滾到修復版本提交
git checkout 6cdf3dc
```

### 回滾到上一個版本
```bash
# 回滾到 origin/main
git checkout origin/main
```

### 回滾特定文件
```bash
# 回滾單個文件到修復版本
git checkout v1.0.0-fixed -- app/controllers/test_case_imports_controller.rb

# 回滾單個文件到上一個版本
git checkout origin/main -- app/controllers/test_case_imports_controller.rb
```

### 查看文件差異
```bash
# 查看當前版本與修復版本的差異
git diff v1.0.0-fixed

# 查看特定文件的差異
git diff v1.0.0-fixed -- app/controllers/test_case_imports_controller.rb
```

## 🚨 緊急回滾步驟

### 如果修改壞了，快速回滾到修復版本：

1. **保存當前修改（可選）**:
   ```bash
   git stash
   ```

2. **回滾到修復版本**:
   ```bash
   git checkout v1.0.0-fixed
   ```

3. **重新啟動 Redmine 服務**:
   ```bash
   cd /Users/jason/redmine/redmine_6.0.6
   docker-compose restart
   ```

### 如果只想回滾特定文件：

1. **回滾特定文件**:
   ```bash
   git checkout v1.0.0-fixed -- app/controllers/test_case_imports_controller.rb
   ```

2. **重新啟動 Redmine 服務**:
   ```bash
   cd /Users/jason/redmine/redmine_6.0.6
   docker-compose restart
   ```

## 📁 重要文件列表

### 核心修復文件
- `app/controllers/test_case_imports_controller.rb` - 測試案例匯入控制器
- `app/controllers/test_plan_imports_controller.rb` - 測試計劃匯入控制器
- `app/controllers/test_case_execution_imports_controller.rb` - 測試執行匯入控制器
- `app/models/test_case_import.rb` - 測試案例匯入模型
- `app/models/test_plan_import.rb` - 測試計劃匯入模型
- `app/models/test_case_execution_import.rb` - 測試執行匯入模型
- `config/routes.rb` - 路由配置
- `init.rb` - 插件初始化
- `lib/test_case_management/test_case_import_concern.rb` - 匯入功能 Concern

### 視圖文件
- `app/views/test_case_imports/new.html.erb` - 測試案例匯入頁面
- `app/views/test_plan_imports/new.html.erb` - 測試計劃匯入頁面
- `app/views/test_case_execution_imports/new.html.erb` - 測試執行匯入頁面
- `app/views/test_cases/show.html.erb` - 測試案例詳情頁面
- `app/views/test_case_executions/show.html.erb` - 測試執行詳情頁面
- `app/views/test_plans/statistics.html.erb` - 測試計劃統計頁面

### 修復報告
- `ALL_IMPORTS_FIX_REPORT.md` - 所有匯入功能修復報告
- `ATTACHMENTS_FIX_REPORT.md` - 附件功能修復報告
- `ROUTING_FIX_REPORT.md` - 路由修復報告
- `STATISTICS_LINK_FIX_REPORT.md` - 統計頁面連結修復報告

## 🔧 測試檢查清單

### 匯入功能測試
- [ ] 測試案例匯入: `http://localhost:3003/projects/t/test_cases/imports/new`
- [ ] 測試計劃匯入: `http://localhost:3003/projects/t/test_plans/imports/new`
- [ ] 測試執行匯入: `http://localhost:3003/projects/t/test_case_executions/imports/new`

### 統計頁面測試
- [ ] 測試計劃統計: `http://localhost:3003/projects/t/test_plans/statistics`
- [ ] 測試案例統計: `http://localhost:3003/projects/t/test_cases/statistics`

### 詳情頁面測試
- [ ] 測試案例詳情頁面連結
- [ ] 測試執行詳情頁面連結
- [ ] 附件功能顯示

## 📝 注意事項

1. **修改前備份**: 在進行任何修改前，建議先創建一個新的分支
2. **測試驗證**: 每次修改後都要測試相關功能
3. **文檔更新**: 修改後要更新相應的修復報告
4. **服務重啟**: 修改後要重啟 Redmine 服務

## 🆘 緊急聯繫

如果遇到無法解決的問題：
1. 立即回滾到修復版本: `git checkout v1.0.0-fixed`
2. 重啟 Redmine 服務: `docker-compose restart`
3. 檢查錯誤日誌: `docker logs redmine_606-redmine-1 --tail 50`

---

**最後更新**: 2025-09-04  
**修復版本**: v1.0.0-fixed  
**狀態**: ✅ 所有功能正常運作
