#!/usr/bin/env ruby

# 驗證插件安裝腳本
puts "=== 驗證測試案例管理插件安裝 ==="
puts

# 檢查插件目錄
puts "📁 檢查插件目錄:"
if Dir.exist?('/usr/src/redmine/plugins/testcase_management')
  puts "  ✅ 插件目錄存在"
else
  puts "  ❌ 插件目錄不存在"
end

puts

# 檢查數據庫表
puts "🗄️  檢查數據庫表:"
tables = ['test_plans', 'test_cases', 'test_case_executions', 'test_case_test_plans']
tables.each do |table|
  if ActiveRecord::Base.connection.table_exists?(table)
    puts "  ✅ 表 #{table} 存在"
  else
    puts "  ❌ 表 #{table} 不存在"
  end
end

puts

# 檢查插件註冊
puts "🔧 檢查插件註冊:"
begin
  plugin = Redmine::Plugin.find(:testcase_management)
  puts "  ✅ 插件已註冊"
  puts "    名稱: #{plugin.name}"
  puts "    版本: #{plugin.version}"
  puts "    作者: #{plugin.author}"
rescue => e
  puts "  ❌ 插件註冊失敗: #{e.message}"
end

puts

# 檢查模型類別
puts "📋 檢查模型類別:"
models = ['TestPlan', 'TestCase', 'TestCaseExecution']
models.each do |model_name|
  begin
    model_class = Object.const_get(model_name)
    puts "  ✅ #{model_name} 模型可用"
  rescue => e
    puts "  ❌ #{model_name} 模型不可用: #{e.message}"
  end
end

puts
puts "=== 驗證完成 ==="
