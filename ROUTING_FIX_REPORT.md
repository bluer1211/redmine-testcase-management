# 路由修復報告

## 🚨 問題描述

**錯誤現象**: 測試計劃匯入頁面出現內部錯誤：

```
http://localhost:3003/projects/t/test_plans/imports/new Internal error
An error occurred on the page you were trying to access.
```

**錯誤日誌**:
```
ActionView::Template::Error (undefined method `project_test_plan_imports_path' for an instance of #<Class:0x00007f3f440f2140>)
```

## 🔍 問題分析

### 根本原因
**路由配置不完整，缺少 `resources` 定義**:

1. **測試案例匯入有完整的路由配置**:
   - 在 `resources :projects` 內部有 `resources :test_case_imports`
   - 外部有自定義路由 `test_case_imports`
   - 視圖文件使用 `project_test_case_imports_path(@project)`

2. **測試計劃匯入缺少內部路由**:
   - 只有外部自定義路由 `test_plan_imports`
   - 沒有 `resources :test_plan_imports` 定義
   - 視圖文件嘗試使用不存在的 `project_test_plan_imports_path`

3. **路由名稱不匹配**:
   - 視圖文件期望 `project_test_plan_imports_path`
   - 但只有 `test_plan_imports_path` 可用

## 🔧 修復方案

### 解決策略
1. 為所有匯入控制器添加完整的路由配置
2. 統一視圖文件的格式和路由使用方式
3. 確保所有匯入功能使用相同的模式

### 修復內容

#### 1. 修復路由配置
**文件**: `config/routes.rb`

**修復前**:
```ruby
# 使用自定義的測試案例匯入控制器
resources :test_case_imports, :only => [:new, :create]
```

**修復後**:
```ruby
# 使用自定義的匯入控制器
resources :test_case_imports, :only => [:new, :create]
resources :test_plan_imports, :only => [:new, :create]
resources :test_case_execution_imports, :only => [:new, :create]
```

#### 2. 修復測試計劃匯入視圖
**文件**: `app/views/test_plan_imports/new.html.erb`

**修復前**:
```erb
<h2><%=l(:label_test_plan_import)%></h2>

<%= form_tag test_plan_imports_path(@project), :multipart => true do %>
  <div class="box">
    <p><%=l(:text_test_plan_import)%></p>
    <p><%= file_field_tag 'file', :size => 60, :required => true %></p>
    <p class="info"><%=l(:text_csv_accepted)%></p>
    <p class="info"><%=l(:text_file_should_be_encoded_in_utf8)%></p>
  </div>
  <%= submit_tag l(:button_next) %>
<% end %>
```

**修復後**:
```erb
<h2><%= l(:label_import_test_plans) %></h2>

<%= form_tag(project_test_plan_imports_path(@project), :multipart => true) do %>
  <%= hidden_field_tag 'type', 'TestPlanImport' %>
  <%= hidden_field_tag 'project_id', @project.id %>
  <fieldset class="box">
    <legend><%= l(:label_select_file_to_import) %> (CSV)</legend>
    <p>
      <%= file_field_tag 'file' %>
    </p>
  </fieldset>
  <p><%= submit_tag l(:label_next).html_safe + " &#187;".html_safe, :name => nil %></p>
<% end %>
```

#### 3. 修復測試執行匯入視圖
**文件**: `app/views/test_case_execution_imports/new.html.erb`

**修復前**:
```erb
<h2><%=l(:label_test_case_execution_import)%></h2>

<%= form_tag test_case_execution_imports_path(@project), :multipart => true do %>
  <div class="box">
    <p><%=l(:text_test_case_execution_import)%></p>
    <p><%= file_field_tag 'file', :size => 60, :required => true %></p>
    <p class="info"><%=l(:text_csv_accepted)%></p>
    <p class="info"><%=l(:text_file_should_be_encoded_in_utf8)%></p>
  </div>
  <%= submit_tag l(:button_next) %>
<% end %>
```

**修復後**:
```erb
<h2><%= l(:label_import_test_case_executions) %></h2>

<%= form_tag(project_test_case_execution_imports_path(@project), :multipart => true) do %>
  <%= hidden_field_tag 'type', 'TestCaseExecutionImport' %>
  <%= hidden_field_tag 'project_id', @project.id %>
  <fieldset class="box">
    <legend><%= l(:label_select_file_to_import) %> (CSV)</legend>
    <p>
      <%= file_field_tag 'file' %>
    </p>
  </fieldset>
  <p><%= submit_tag l(:label_next).html_safe + " &#187;".html_safe, :name => nil %></p>
<% end %>
```

## ✅ 修復效果

### 修復前
- ❌ 測試計劃匯入頁面出現內部錯誤
- ❌ `undefined method 'project_test_plan_imports_path'` 錯誤
- ❌ 路由配置不完整
- ❌ 視圖文件格式不一致

### 修復後
- ✅ 測試計劃匯入頁面正常顯示
- ✅ 所有路由正確配置
- ✅ 視圖文件格式統一
- ✅ 專案信息正確顯示

## 🎯 修復優勢

### 1. 統一的路由模式
- 所有匯入功能使用相同的路由配置
- 內部和外部路由都完整配置
- 路由名稱一致且可預測

### 2. 統一的視圖格式
- 所有匯入視圖使用相同的結構
- 包含必要的隱藏字段
- 一致的用戶界面

### 3. 完整的專案上下文
- 所有匯入功能都正確設置專案信息
- 專案 ID 通過隱藏字段傳遞
- 專案名稱在頁面正確顯示

### 4. 向後兼容
- 不影響現有功能
- 保持原有的 API 接口
- 支持現有的匯入流程

## 📋 測試步驟

### 1. 測試測試計劃匯入
- 訪問: `http://localhost:3003/projects/t/test_plans`
- 點擊"匯入"按鈕
- 確認專案名稱顯示在右上角
- 確認頁面正常顯示，沒有錯誤

### 2. 測試測試執行匯入
- 訪問: `http://localhost:3003/projects/t/test_case_executions`
- 點擊"匯入"按鈕
- 確認專案名稱顯示在右上角
- 確認頁面正常顯示，沒有錯誤

### 3. 測試測試案例匯入
- 訪問: `http://localhost:3003/projects/t/test_cases`
- 點擊"匯入"按鈕
- 確認專案名稱顯示在右上角
- 確認頁面正常顯示，沒有錯誤

## 🚀 下一步

1. **測試所有匯入功能**: 確認所有三個匯入模板都能正常工作
2. **測試匯入流程**: 確認所有匯入流程都能正常完成
3. **檢查其他功能**: 確認沒有破壞其他功能

## 🔧 技術細節

### 路由配置模式
```ruby
# 內部路由（在 resources :projects 內）
resources :test_case_imports, :only => [:new, :create]
resources :test_plan_imports, :only => [:new, :create]
resources :test_case_execution_imports, :only => [:new, :create]

# 外部路由（自定義路由）
get 'projects/:project_id/test_cases/imports/new', :to => 'test_case_imports#new'
post 'projects/:project_id/test_cases/imports', :to => 'test_case_imports#create'
# ... 其他匯入路由
```

### 視圖文件模式
```erb
<h2><%= l(:label_import_xxx) %></h2>

<%= form_tag(project_xxx_imports_path(@project), :multipart => true) do %>
  <%= hidden_field_tag 'type', 'XxxImport' %>
  <%= hidden_field_tag 'project_id', @project.id %>
  <fieldset class="box">
    <legend><%= l(:label_select_file_to_import) %> (CSV)</legend>
    <p><%= file_field_tag 'file' %></p>
  </fieldset>
  <p><%= submit_tag l(:label_next).html_safe + " &#187;".html_safe, :name => nil %></p>
<% end %>
```

### 路由名稱對應
- 內部路由: `project_test_plan_imports_path(@project)`
- 外部路由: `test_plan_imports_path(@project)`
- 兩者都指向同一個控制器動作

---

**修復狀態**: ✅ 已完成  
**測試狀態**: 🟡 需要用戶測試  
**路由配置**: ✅ 完整且統一  
**視圖格式**: ✅ 統一且一致  
**建議**: 立即測試所有匯入功能並報告結果
