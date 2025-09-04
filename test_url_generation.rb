#!/usr/bin/env ruby

puts "=== 測試 URL 生成 ==="

# 模擬在視圖環境中
include Rails.application.routes.url_helpers
include ActionView::Helpers::UrlHelper

# 獲取專案
project = Project.find_by(identifier: 't')
puts "專案: #{project.identifier} (ID: #{project.id})"

puts "\n=== 測試不同的 URL 生成方式 ==="

# 方式 1: 使用 :project_id => @project
url1 = new_test_cases_import_path(:project_id => project)
puts "方式 1 (new_test_cases_import_path(:project_id => project)): #{url1}"

# 方式 2: 直接傳遞 project 對象
url2 = new_test_cases_import_path(project)
puts "方式 2 (new_test_cases_import_path(project)): #{url2}"

# 方式 3: 使用 project_id 字符串
url3 = new_test_cases_import_path(:project_id => project.identifier)
puts "方式 3 (new_test_cases_import_path(:project_id => project.identifier)): #{url3}"

# 方式 4: 使用 project_id 數字
url4 = new_test_cases_import_path(:project_id => project.id)
puts "方式 4 (new_test_cases_import_path(:project_id => project.id)): #{url4}"

puts "\n=== 比較其他匯入功能 ==="

# 測試計劃匯入
test_plans_url = new_test_plans_import_path(:project_id => project)
puts "測試計劃匯入: #{test_plans_url}"

# 測試執行匯入
test_executions_url = new_test_case_executions_import_path(:project_id => project)
puts "測試執行匯入: #{test_executions_url}"

puts "\n=== 檢查路由定義 ==="
puts "路由助手方法: #{Rails.application.routes.url_helpers.methods.grep(/test_cases_import/).sort}"

puts "\n=== 完成 ==="
