# 測試案例管理插件 - 繁體中文設定指南

## 概述

本文件說明如何為 Redmine 測試案例管理插件啟用繁體中文翻譯功能。

## 已完成的設定

### 1. 語言檔案
- 已建立 `config/locales/zh-TW.yml` 繁體中文翻譯檔案
- 包含所有插件相關的介面文字翻譯
- 特別針對 Excel 匯入功能的欄位對應進行翻譯

### 2. 插件初始化
- 已更新 `init.rb` 檔案以支援多語言載入
- 自動載入 `config/locales/` 目錄下的所有語言檔案

## 啟用繁體中文的步驟

### 步驟 1: 確認語言檔案存在
確認以下檔案已存在：
```
redmine/plugins/testcase_management/config/locales/zh-TW.yml
```

### 步驟 2: 重啟 Redmine 服務
```bash
# 如果使用 Docker
docker-compose restart

# 如果使用傳統安裝
sudo systemctl restart redmine
# 或
sudo service redmine restart
```

### 步驟 3: 在 Redmine 中設定語言
1. 以管理員身份登入 Redmine
2. 前往「管理」→「設定」→「顯示」
3. 在「預設語言」下拉選單中選擇「繁體中文 (zh-TW)」
4. 儲存設定

### 步驟 4: 清除快取（可選）
如果翻譯沒有立即生效，請清除快取：
```bash
# 清除 Rails 快取
cd /path/to/redmine
bundle exec rake tmp:cache:clear
```

## Excel 匯入欄位對應

### 測試案例匯入欄位
| 英文欄位 | 繁體中文翻譯 | 說明 |
|---------|-------------|------|
| project_id | 專案 | 目標專案 |
| test_case_id | 測試案例ID | 用於更新現有測試案例 |
| test_plan | 測試計畫 | 關聯的測試計畫 |
| test_case | 測試案例 | 測試案例名稱 |
| test_case_update | 更新現有測試案例 | 是否覆蓋現有案例 |
| user | 使用者 | 負責人 |
| environment | 測試環境 | 執行環境 |
| scenario | 測試情境 | 測試步驟 |
| expected | 預期結果 | 期望結果 |

### 測試計畫匯入欄位
| 英文欄位 | 繁體中文翻譯 | 說明 |
|---------|-------------|------|
| project_id | 專案 | 目標專案 |
| test_plan_id | 測試計畫ID | 用於更新現有計畫 |
| test_plan | 測試計畫 | 計畫名稱 |
| issue_status | 狀態 | 計畫狀態 |
| estimated_bug | 預估錯誤數 | 預期發現的錯誤數量 |
| user | 使用者 | 負責人 |
| begin_date | 開始日期 | 計畫開始日期 |
| end_date | 結束日期 | 計畫結束日期 |
| test_case_ids | 測試案例 | 關聯的測試案例ID |

### 測試執行結果匯入欄位
| 英文欄位 | 繁體中文翻譯 | 說明 |
|---------|-------------|------|
| project_id | 專案 | 目標專案 |
| test_case | 測試案例 | 執行的測試案例 |
| test_plan | 測試計畫 | 所屬測試計畫 |
| result | 執行結果 | 成功/失敗 |
| user | 使用者 | 執行者 |
| issue | 問題 | 關聯的問題 |
| comment | 備註 | 執行備註 |
| execution_date | 執行日期 | 執行時間 |

## 驗證翻譯

### 檢查項目
1. 插件選單顯示為「測試案例管理」
2. 測試案例頁面標題為「測試案例」
3. 測試計畫頁面標題為「測試計畫」
4. 匯入功能中的欄位對應顯示繁體中文
5. 錯誤訊息和確認對話框顯示繁體中文

### 測試匯入功能
1. 準備包含繁體中文欄位標題的 Excel 檔案
2. 使用匯入功能，確認欄位對應介面顯示繁體中文
3. 執行匯入，確認成功訊息為繁體中文

## 故障排除

### 翻譯未生效
1. 確認 `zh-TW.yml` 檔案語法正確
2. 重啟 Redmine 服務
3. 清除快取
4. 檢查 Redmine 語言設定

### 匯入欄位對應問題
1. 確認 Excel 檔案欄位標題與翻譯檔案中的欄位名稱一致
2. 檢查 CSV 編碼是否為 UTF-8
3. 確認欄位對應設定正確

## 技術細節

### 語言檔案結構
```yaml
zh-TW:
  project_module_testcase_management: "測試案例管理"
  label_test_cases: "測試案例"
  # ... 其他翻譯項目
```

### 支援的語言代碼
- `en`: 英文
- `ja`: 日文
- `zh-TW`: 繁體中文

## 聯絡資訊

如有問題或建議，請聯絡系統管理員或參考插件官方文件。
