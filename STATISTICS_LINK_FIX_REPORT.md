# 統計頁面連結修復報告

## 🚨 問題描述

**錯誤現象**: 在測試計劃統計頁面點擊測試計劃連結時，出現專案未找到錯誤：

```
http://localhost:3003/projects/Test%20Project/test_plans/4 The project was not found.
Back to lists
```

**問題分析**: 連結使用了錯誤的專案標識符，導致無法找到正確的專案。

## 🔍 問題分析

### 根本原因
**視圖文件中使用了錯誤的專案標識符**:

1. **錯誤的連結生成方式**:
   ```erb
   <%= link_to test_plan.id, "/projects/#{@project.name}/test_plans/#{test_plan.id}" %>
   <%= link_to test_plan.name, "/projects/#{@project.name}/test_plans/#{test_plan.id}" %>
   ```

2. **問題所在**:
   - 使用了 `@project.name` 而不是 `@project.identifier`
   - 專案名稱可能包含空格，導致 URL 編碼問題
   - 硬編碼的 URL 路徑，不遵循 Rails 路由慣例

3. **正確的方式**:
   - 使用 Rails 的路由助手方法
   - 使用 `@project.identifier` 作為專案標識符
   - 讓 Rails 自動生成正確的 URL

## 🔧 修復方案

### 解決策略
使用 Rails 的路由助手方法來生成正確的連結，而不是硬編碼 URL 路徑。

### 修復內容

#### 修復測試計劃統計頁面
**文件**: `app/views/test_plans/statistics.html.erb`

**修復前**:
```erb
<td class="id"><%= link_to test_plan.id, "/projects/#{@project.name}/test_plans/#{test_plan.id}" %></td>
<td class="name"><%= link_to test_plan.name, "/projects/#{@project.name}/test_plans/#{test_plan.id}" %></td>
```

**修復後**:
```erb
<td class="id"><%= link_to test_plan.id, project_test_plan_path(@project, test_plan) %></td>
<td class="name"><%= link_to test_plan.name, project_test_plan_path(@project, test_plan) %></td>
```

## ✅ 修復效果

### 修復前
- ❌ 點擊測試計劃連結時出現 "The project was not found" 錯誤
- ❌ 使用專案名稱而不是專案標識符
- ❌ URL 編碼問題（空格被編碼為 %20）
- ❌ 硬編碼的 URL 路徑

### 修復後
- ✅ 點擊測試計劃連結正常跳轉到正確的專案
- ✅ 使用正確的專案標識符
- ✅ 沒有 URL 編碼問題
- ✅ 使用 Rails 標準的路由助手方法

## 🎯 修復優勢

### 1. 正確的專案識別
- 使用 `@project.identifier` 而不是 `@project.name`
- 專案標識符是唯一的，不會有編碼問題
- 符合 Redmine 的 URL 結構慣例

### 2. Rails 標準做法
- 使用路由助手方法而不是硬編碼 URL
- 自動處理 URL 生成和參數傳遞
- 更容易維護和修改

### 3. 更好的用戶體驗
- 連結正常工作，不會出現錯誤頁面
- 用戶可以正常導航到測試計劃詳情頁面
- 保持一致的導航體驗

### 4. 向後兼容
- 不影響現有功能
- 保持原有的頁面結構
- 只修復連結生成方式

## 📋 測試步驟

### 1. 測試測試計劃統計頁面
- 訪問: `http://localhost:3003/projects/t/test_plans/statistics`
- 點擊任何測試計劃的 ID 或名稱連結
- 確認正常跳轉到正確的測試計劃詳情頁面
- 確認沒有 "The project was not found" 錯誤

### 2. 測試其他統計頁面
- 訪問: `http://localhost:3003/projects/t/test_cases/statistics`
- 確認測試案例統計頁面正常工作
- 確認沒有類似的連結問題

## 🚀 下一步

1. **測試統計功能**: 確認所有統計頁面的連結都正常工作
2. **檢查其他頁面**: 確認沒有其他類似的硬編碼 URL 問題
3. **用戶體驗**: 確認用戶可以正常導航到所有相關頁面

## 🔧 技術細節

### 路由助手方法
```erb
<!-- 錯誤的方式 -->
<%= link_to test_plan.name, "/projects/#{@project.name}/test_plans/#{test_plan.id}" %>

<!-- 正確的方式 -->
<%= link_to test_plan.name, project_test_plan_path(@project, test_plan) %>
```

### 專案標識符 vs 專案名稱
- **專案標識符 (`identifier`)**: 用於 URL，唯一且不包含空格
- **專案名稱 (`name`)**: 用於顯示，可能包含空格和特殊字符

### Rails 路由慣例
- 使用路由助手方法生成 URL
- 自動處理參數傳遞和 URL 編碼
- 更容易維護和修改

---

**修復狀態**: ✅ 已完成  
**測試狀態**: 🟡 需要用戶測試  
**連結修復**: ✅ 使用正確的路由助手  
**專案識別**: ✅ 使用正確的專案標識符  
**建議**: 立即測試統計頁面的連結功能並報告結果
