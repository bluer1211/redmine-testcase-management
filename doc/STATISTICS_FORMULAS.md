# 測試計劃統計計算公式文件

## 概述
本文檔詳細說明測試計劃統計頁面中各種指標的計算公式，包括單個測試計劃的統計和合計統計。

## 統計頁面欄位對照表

| 欄位名稱 | 英文欄位 | 說明 |
|---------|---------|------|
| # | id | 測試計劃編號 |
| 測試計劃 | name | 測試計劃名稱 |
| 使用者 | user | 測試計劃負責人 |
| 測試案例數量 | test_cases | 該測試計劃包含的測試案例總數 |
| 未執行 | not_executed | 尚未執行的測試案例數量 |
| 成功 | succeeded | 執行成功的測試案例數量 |
| 失敗 | failed | 執行失敗的測試案例數量 |
| 成功率 | succeeded_rate | 成功測試案例佔總測試案例的百分比 |
| 進度率 | progress_rate | 已執行測試案例佔總測試案例的百分比 |
| 預估錯誤數 | estimated_bug | 預估可能發現的錯誤數量 |
| 發現錯誤 | detected_bug | 實際發現的錯誤數量 |
| 剩餘錯誤 | remained_bug | 尚未修復的錯誤數量 |
| 修復率 | fixed_rate | 已修復錯誤佔發現錯誤的百分比 |

## 基本數據來源

### 測試案例執行狀態
- **未執行**：`result IS NULL`
- **成功**：`result = '1'`
- **失敗**：`result = '0'`

### 問題狀態
- **發現錯誤**：`issues.id IS NOT NULL`
- **已修復**：`issue_statuses.is_closed = '1'`
- **剩餘錯誤**：`issue_statuses.is_closed = '0' AND issues.id IS NOT NULL`

## 單個測試計劃統計公式

### 1. 測試案例數量 (test_cases)
```
測試案例數量 = test_plan.test_cases.size
```
**說明**：計算該測試計劃包含的所有測試案例總數

### 2. 未執行 (not_executed)
```
未執行 = SUM(CASE WHEN TPTCTCE.result IS NULL THEN 1 ELSE 0 END)
```
**說明**：統計尚未執行的測試案例數量（result 為 NULL）

### 3. 成功 (succeeded)
```
成功 = SUM(CASE WHEN TPTCTCE.result = '1' THEN 1 ELSE 0 END)
```
**說明**：統計執行成功的測試案例數量（result = '1'）

### 4. 失敗 (failed)
```
失敗 = SUM(CASE WHEN TPTCTCE.result = '0' THEN 1 ELSE 0 END)
```
**說明**：統計執行失敗的測試案例數量（result = '0'）

### 5. 成功率 (succeeded_rate)
```ruby
if test_plan.test_cases.size > 0
  成功率 = ((test_plan.count_succeeded / test_plan.test_cases.size.to_f) * 100).round
else
  成功率 = '-'
end
```
**說明**：成功測試案例數 ÷ 總測試案例數 × 100%，四捨五入到整數

### 6. 進度率 (progress_rate)
```ruby
if test_plan.test_cases.size > 0
  進度率 = (((test_plan.count_succeeded + test_plan.count_failed) / test_plan.test_cases.size.to_f) * 100).round
else
  進度率 = '-'
end
```
**說明**：(成功數 + 失敗數) ÷ 總測試案例數 × 100%，表示已執行的測試案例比例

### 7. 預估錯誤數 (estimated_bug)
```
預估錯誤數 = test_plan.estimated_bug
```
**說明**：測試計劃中預先估計可能發現的錯誤數量

### 8. 發現錯誤 (detected_bug)
```
發現錯誤 = SUM(CASE WHEN issues.id IS NOT NULL THEN 1 ELSE 0 END)
```
**說明**：統計實際發現的錯誤數量（關聯到問題的測試案例執行）

### 9. 剩餘錯誤 (remained_bug)
```
剩餘錯誤 = SUM(CASE WHEN TCEIS.is_closed = '0' AND issues.id IS NOT NULL THEN 1 ELSE 0 END)
```
**說明**：統計尚未修復的錯誤數量（問題狀態為未關閉）

### 10. 修復率 (fixed_rate)
```ruby
if test_plan.detected_bug > 0
  修復率 = ((test_plan.fixed_bug / test_plan.detected_bug.to_f) * 100).round
else
  修復率 = '-'
end
```
**說明**：已修復錯誤數 ÷ 發現錯誤數 × 100%，四捨五入到整數

## 合計統計公式（合計行）

### 1. 總測試案例數量 (test_cases)
```ruby
total_test_cases = @test_plans.sum { |tp| tp.test_cases.size }
```
**說明**：所有測試計劃的測試案例數量總和

### 2. 總未執行數量 (not_executed)
```ruby
total_not_executed = @test_plans.sum(&:count_not_executed)
```
**說明**：所有測試計劃中未執行的測試案例數量總和

### 3. 總成功數量 (succeeded)
```ruby
total_succeeded = @test_plans.sum(&:count_succeeded)
```
**說明**：所有測試計劃中成功的測試案例數量總和

### 4. 總失敗數量 (failed)
```ruby
total_failed = @test_plans.sum(&:count_failed)
```
**說明**：所有測試計劃中失敗的測試案例數量總和

### 5. 總體成功率 (succeeded_rate)
```ruby
if total_test_cases > 0
  total_succeeded_rate = ((total_succeeded / total_test_cases.to_f) * 100).round
else
  total_succeeded_rate = '-'
end
```
**說明**：總成功數 ÷ 總測試案例數 × 100%，四捨五入到整數

### 6. 總體進度率 (progress_rate)
```ruby
if total_test_cases > 0
  total_progress_rate = (((total_succeeded + total_failed) / total_test_cases.to_f) * 100).round
else
  total_progress_rate = '-'
end
```
**說明**：(總成功數 + 總失敗數) ÷ 總測試案例數 × 100%，表示整體已執行的測試案例比例

### 7. 總預估錯誤數 (estimated_bug)
```ruby
total_estimated_bug = @test_plans.sum(&:estimated_bug)
```
**說明**：所有測試計劃的預估錯誤數量總和

### 8. 總發現錯誤數 (detected_bug)
```ruby
total_detected_bug = @test_plans.sum(&:detected_bug)
```
**說明**：所有測試計劃中發現的錯誤數量總和

### 9. 總剩餘錯誤數 (remained_bug)
```ruby
total_remained_bug = @test_plans.sum(&:remained_bug)
```
**說明**：所有測試計劃中剩餘的錯誤數量總和

### 10. 總體修復率 (fixed_rate)
```ruby
if total_detected_bug > 0
  total_fixed_rate = ((total_fixed_bug / total_detected_bug.to_f) * 100).round
else
  total_fixed_rate = '-'
end
```
**說明**：總已修復錯誤數 ÷ 總發現錯誤數 × 100%，四捨五入到整數

## SQL 查詢結構

### 主要 JOIN 查詢
```sql
LEFT JOIN (
  SELECT * FROM (
    SELECT *, row_number() OVER (
      PARTITION BY test_plan_id, test_case_id
      ORDER BY execution_date desc, id desc
    ) AS rownum
    FROM test_case_executions
  ) AS TCE
  WHERE TCE.rownum = 1
) AS TPTCTCE
  ON TPTCTCE.test_plan_id = test_case_test_plans.test_plan_id 
  AND TPTCTCE.test_case_id = test_case_test_plans.test_case_id 
LEFT JOIN issues ON TPTCTCE.issue_id = issues.id
LEFT JOIN issue_statuses AS TCEIS ON TCEIS.id = issues.status_id
```

### SELECT 查詢
```sql
SELECT 
  test_plans.id, 
  test_plans.name, 
  test_plans.user_id, 
  test_plans.estimated_bug,
  SUM(CASE WHEN TPTCTCE.result IS NULL THEN 1 ELSE 0 END) AS count_not_executed,
  SUM(CASE WHEN TPTCTCE.result = '1' THEN 1 ELSE 0 END) AS count_succeeded,
  SUM(CASE WHEN TPTCTCE.result = '0' THEN 1 ELSE 0 END) AS count_failed,
  SUM(CASE WHEN issues.id IS NOT NULL THEN 1 ELSE 0 END) AS detected_bug,
  SUM(CASE WHEN TCEIS.is_closed = '1' THEN 1 ELSE 0 END) AS fixed_bug,
  SUM(CASE WHEN TCEIS.is_closed = '0' AND issues.id IS NOT NULL THEN 1 ELSE 0 END) AS remained_bug
FROM test_plans
JOIN test_cases ON test_plans.id = test_cases.test_plan_id
-- ... JOIN 查詢如上
WHERE test_plans.project_id = ?
GROUP BY test_plans.id
ORDER BY test_plans.id DESC
```

## 注意事項

1. **最新執行記錄**：使用 `row_number() OVER (PARTITION BY test_plan_id, test_case_id ORDER BY execution_date desc, id desc)` 確保每個測試案例只取最新的執行記錄。

2. **除零處理**：所有百分比計算都包含除零檢查，當分母為0時返回 '-'。

3. **四捨五入**：所有百分比結果使用 `.round` 方法進行四捨五入。

4. **數據一致性**：合計統計使用與單個測試計劃相同的計算邏輯，確保數據一致性。

## 實際範例說明

### 範例數據
假設有一個測試計劃包含以下數據：
- 測試案例數量：10
- 未執行：3
- 成功：5
- 失敗：2
- 預估錯誤數：8
- 發現錯誤：3
- 剩餘錯誤：1

### 計算結果
- **成功率** = (5 ÷ 10) × 100% = 50%
- **進度率** = ((5 + 2) ÷ 10) × 100% = 70%
- **修復率** = ((3 - 1) ÷ 3) × 100% = 67%

### 合計行範例
假設有3個測試計劃：
- 測試計劃A：測試案例10個，成功5個，失敗2個
- 測試計劃B：測試案例8個，成功6個，失敗1個  
- 測試計劃C：測試案例12個，成功8個，失敗3個

**合計計算**：
- 總測試案例數量 = 10 + 8 + 12 = 30
- 總成功數量 = 5 + 6 + 8 = 19
- 總失敗數量 = 2 + 1 + 3 = 6
- 總體成功率 = (19 ÷ 30) × 100% = 63%
- 總體進度率 = ((19 + 6) ÷ 30) × 100% = 83%

## 版本信息
- 文件版本：1.1
- 最後更新：2025-09-11
- 適用版本：Redmine 6.0.6 + TestCase Management Plugin
