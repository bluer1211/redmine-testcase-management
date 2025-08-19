# 分支結構說明

## 🌿 分支策略

本專案採用 Git Flow 分支策略，確保開發流程的穩定性和可維護性。

## 📋 分支說明

### 主要分支

#### `main` 分支
- **用途**: 生產環境的穩定版本
- **來源**: 從 `develop` 分支合併
- **保護**: 禁止直接推送，必須通過 Pull Request
- **版本**: 對應正式發布版本

#### `develop` 分支
- **用途**: 開發環境的整合分支
- **來源**: 從 `feature/*` 分支合併
- **保護**: 建議禁止直接推送
- **版本**: 對應開發版本

### 功能分支

#### `feature/*` 分支
- **用途**: 開發新功能
- **命名**: `feature/功能名稱`
- **來源**: 從 `develop` 分支建立
- **合併**: 完成後合併回 `develop` 分支

#### `hotfix/*` 分支
- **用途**: 修復生產環境的緊急問題
- **命名**: `hotfix/問題描述`
- **來源**: 從 `main` 分支建立
- **合併**: 修復後合併回 `main` 和 `develop` 分支

#### `release/*` 分支
- **用途**: 準備新版本發布
- **命名**: `release/版本號`
- **來源**: 從 `develop` 分支建立
- **合併**: 發布後合併回 `main` 和 `develop` 分支

## 🔄 工作流程

### 開發新功能

1. **建立功能分支**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/new-feature
   ```

2. **開發功能**
   ```bash
   # 進行開發工作
   git add .
   git commit -m "feat: add new feature"
   ```

3. **合併功能分支**
   ```bash
   git checkout develop
   git merge feature/new-feature
   git push origin develop
   git branch -d feature/new-feature
   ```

### 發布新版本

1. **建立發布分支**
   ```bash
   git checkout develop
   git checkout -b release/v1.6.4
   ```

2. **準備發布**
   ```bash
   # 更新版本號
   # 更新 CHANGELOG.md
   # 修復最後的問題
   git commit -m "chore: prepare release v1.6.4"
   ```

3. **合併發布分支**
   ```bash
   git checkout main
   git merge release/v1.6.4
   git tag v1.6.4
   git checkout develop
   git merge release/v1.6.4
   git branch -d release/v1.6.4
   ```

### 修復緊急問題

1. **建立修復分支**
   ```bash
   git checkout main
   git checkout -b hotfix/critical-bug
   ```

2. **修復問題**
   ```bash
   # 修復問題
   git commit -m "fix: resolve critical bug"
   ```

3. **合併修復分支**
   ```bash
   git checkout main
   git merge hotfix/critical-bug
   git tag v1.6.3.1
   git checkout develop
   git merge hotfix/critical-bug
   git branch -d hotfix/critical-bug
   ```

## 📝 提交訊息規範

### 格式
```
<type>(<scope>): <subject>

<body>

<footer>
```

### 類型 (type)
- `feat`: 新功能
- `fix`: 錯誤修復
- `docs`: 文件更新
- `style`: 程式碼格式調整
- `refactor`: 程式碼重構
- `test`: 測試相關
- `chore`: 建置過程或輔助工具的變動

### 範例
```
feat(testcase): add CSV export functionality

- Add CSV export for test cases
- Support custom column selection
- Add export progress indicator

Closes #123
```

## 🛡️ 分支保護規則

### main 分支
- 要求 Pull Request 審查
- 要求狀態檢查通過
- 禁止直接推送
- 要求線性歷史

### develop 分支
- 建議 Pull Request 審查
- 要求狀態檢查通過
- 允許維護者直接推送

## 📊 分支狀態

| 分支 | 狀態 | 最後更新 | 版本 |
|------|------|----------|------|
| main | 🟢 穩定 | 2025-01-XX | v1.6.3 |
| develop | 🟡 開發中 | 2025-01-XX | v1.6.4-dev |
| feature/github-integration | 🟡 開發中 | 2025-01-XX | - |

## 🔧 常用指令

### 查看分支
```bash
git branch -a
```

### 切換分支
```bash
git checkout <branch-name>
# 或使用新的語法
git switch <branch-name>
```

### 建立並切換分支
```bash
git checkout -b <branch-name>
# 或使用新的語法
git switch -c <branch-name>
```

### 刪除分支
```bash
git branch -d <branch-name>  # 安全刪除
git branch -D <branch-name>  # 強制刪除
```

### 推送分支
```bash
git push origin <branch-name>
```

### 拉取分支
```bash
git pull origin <branch-name>
```

---

**注意**: 請遵循此分支策略以確保專案的穩定性和可維護性。
