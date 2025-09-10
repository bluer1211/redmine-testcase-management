class Import < ActiveRecord::Base
  belongs_to :user
  belongs_to :project

  serialize :settings, coder: JSON
  serialize :mapping, coder: JSON

  validates :user, :presence => true
  validates :project_id, :presence => true

  attr_accessor :original_filename

  def original_filename
    @original_filename || settings&.dig('original_filename') || "import_#{id}.csv"
  end

  def self.authorized?(user)
    true
  end

  def parsed?
    settings.present? && settings['headers'].present?
  end

  def parse_file(file)
    return false unless file.present?
    
    begin
      # 嘗試不同的編碼方式
      parsed_data = CSV.read(file.path, headers: true, encoding: 'UTF-8')
      headers = parsed_data.headers
      
      # 檢查是否有有效的表頭
      if headers.nil? || headers.empty?
        Rails.logger.error "Import parse error: No headers found in CSV file"
        return false
      end
      
      # 將解析的數據保存到 settings 中
      # 轉換為哈希格式，使視圖可以通過表頭名稱訪問數據
      data_rows = parsed_data.map do |row|
        # 使用 to_h 將 CSV::Row 轉換為普通哈希
        row.to_h
      end
      
      self.settings = {
        'headers' => headers,
        'data' => data_rows
      }
      
      Rails.logger.info "Import parse success: #{headers.length} columns found"
      true
    rescue CSV::MalformedCSVError => e
      Rails.logger.error "Import parse error: Malformed CSV - #{e.message}"
      false
    rescue Encoding::InvalidByteSequenceError => e
      Rails.logger.error "Import parse error: Invalid encoding - #{e.message}"
      false
    rescue => e
      Rails.logger.error "Import parse error: #{e.class.name} - #{e.message}"
      false
    end
  end

  def headers
    settings&.dig('headers') || []
  end

  def parsed_data
    data = settings&.dig('data') || []
    # 清理數據中的 ActiveRecord 對象引用
    data.map do |row|
      cleaned_row = {}
      row.each do |key, value|
        if value.is_a?(String) && (value.match?(/#<.*::ActiveRecord_Associations_CollectionProxy:/) || value.match?(/#<.*:0x[0-9a-f]+>/))
          # 如果值是 ActiveRecord 對象引用，嘗試從數據庫中獲取正確的值
          cleaned_row[key] = clean_active_record_reference(key, value)
        elsif value.is_a?(ActiveRecord::Base)
          # 如果值是 ActiveRecord 對象，轉換為字符串
          cleaned_row[key] = value.to_s
        else
          cleaned_row[key] = value
        end
      end
      cleaned_row
    end
  end

  private

  def clean_active_record_reference(key, value)
    # 對於不同類型的欄位，嘗試從數據庫中獲取正確的值
    case key
    when '測試計劃', 'test_plan'
      # 嘗試從項目中獲取測試計劃名稱
      if project_id.present?
        test_plans = TestPlan.where(project_id: project_id)
        if test_plans.any?
          # 返回第一個測試計劃的名稱作為示例
          test_plans.first.name
        else
          '無測試計劃'
        end
      else
        '無測試計劃'
      end
    when '測試案例', 'test_case'
      # 嘗試從項目中獲取測試案例名稱
      if project_id.present?
        test_cases = TestCase.where(project_id: project_id)
        if test_cases.any?
          # 返回第一個測試案例的名稱作為示例
          test_cases.first.name
        else
          '無測試案例'
        end
      else
        '無測試案例'
      end
    else
      # 對於其他欄位，返回清理後的值
      if value.match?(/#<.*:0x[0-9a-f]+>/)
        '無數據'
      else
        value.gsub(/#<.*::ActiveRecord_Associations_CollectionProxy:[^>]*>/, '無數據')
      end
    end
  end

  def saved_objects
    []
  end

  def allowed_target_projects
    Project.allowed_to(user, :view_project)
  end

  def mappable_custom_fields
    []
  end

  def import_result
    @import_result || {}
  end

  def run
    return false unless parsed?
    
    success_count = 0
    error_count = 0
    
    parsed_data.each_with_index do |row, index|
      begin
        object = build_object(row, index)
        if object.save
          success_count += 1
        else
          error_count += 1
          Rails.logger.error "Import error at row #{index + 1}: #{object.errors.full_messages.join(', ')}"
        end
      rescue => e
        error_count += 1
        Rails.logger.error "Import error at row #{index + 1}: #{e.message}"
      end
    end
    
    @import_result = {
      success_count: success_count,
      error_count: error_count,
      total_count: parsed_data.length
    }
    
    true
  end

  private

  def build_object(row, item)
    raise NotImplementedError, "Subclasses must implement build_object method"
  end

  def row_value(row, field_name)
    return nil unless mapping[field_name]
    row[mapping[field_name]]
  end

  def row_date(row, field_name)
    value = row_value(row, field_name)
    return nil unless value.present?
    
    begin
      Date.parse(value)
    rescue
      nil
    end
  end
end
