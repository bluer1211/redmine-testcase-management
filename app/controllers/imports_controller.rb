class ImportsController < ApplicationController
  before_action :find_project
  before_action :authorize_import
  before_action :find_import, :only => [:show, :settings, :mapping, :run]

  def new
    @import = import_class.new
    @import.user = User.current
    @import.project = @project
  end

  def create
    @import = import_class.new
    @import.user = User.current
    @import.project_id = @project.id  # 直接設置 project_id
    @import.original_filename = params[:file].original_filename if params[:file]

    Rails.logger.info "Creating import: project_id=#{@project.id}, user_id=#{User.current.id}, @project=#{@project.inspect}"

    if @import.save
      Rails.logger.info "Import saved successfully: #{@import.inspect}"
      if @import.parse_file(params[:file])
        # 將檔案名稱保存到 settings 中
        @import.settings = @import.settings.merge('original_filename' => @import.original_filename)
        @import.save! # 保存解析的數據和檔案名稱
        redirect_to project_import_path(@project, @import)
      else
        flash.now[:error] = l(:error_import_file_parsing)
        Rails.logger.error "Import failed: File parsing failed for #{@import.original_filename}"
        render :action => 'new'
      end
    else
      flash.now[:error] = l(:error_import_creation)
      Rails.logger.error "Import failed: #{@import.errors.full_messages.join(', ')}"
      Rails.logger.error "Import object: #{@import.inspect}"
      render :action => 'new'
    end
  end

  def show
    if @import.import_result.present?
      # 顯示導入結果
      @import_result = @import.import_result
    else
      # 顯示預覽 - 文件應該已經在創建時解析過了
      unless @import.parsed?
        flash.now[:error] = l(:error_import_file_not_parsed)
        redirect_to project_test_cases_path(@project)
        return
      end
    end
  end

  def settings
    if request.post?
      # 只更新 CSV 設定，保留已解析的 headers 和 data
      current_settings = @import.settings || {}
      csv_settings = params.require(:settings).permit(:separator, :wrapper, :encoding, :project_id).to_h
      
      # 深度合併設定，確保 headers 和 data 不會被覆蓋
      merged_settings = current_settings.deep_merge(csv_settings)
      @import.settings = merged_settings
      
      Rails.logger.info "Settings update: current=#{current_settings.inspect}, new=#{csv_settings.inspect}, merged=#{merged_settings.inspect}"
      
      if @import.save
        redirect_to mapping_project_import_path(@project, @import)
      end
    end
  end

  def mapping
    if request.post?
      @import.mapping = params[:mapping]
      if @import.save
        redirect_to run_project_import_path(@project, @import)
      end
    end
  end

  def run
    if request.post?
      @import.run
      
      # 根據匯入類型導向不同的頁面
      case @import.class.name
      when 'TestCaseImport'
        redirect_to project_test_cases_path(@project), notice: l(:notice_test_case_import_completed)
      when 'TestPlanImport'
        redirect_to project_test_plans_path(@project), notice: l(:notice_test_plan_import_completed)
      when 'TestCaseExecutionImport'
        redirect_to project_test_case_executions_path(@project), notice: l(:notice_test_case_execution_import_completed)
      else
        redirect_to project_test_cases_path(@project), notice: l(:notice_import_completed)
      end
    end
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_import
    unless import_class.authorized?(User.current)
      raise ::Unauthorized
    end
  end

  def find_import
    @import = Import.includes(:project).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def import_class
    case params[:type]
    when 'TestCaseImport'
      TestCaseImport
    when 'TestPlanImport'
      TestPlanImport
    when 'TestCaseExecutionImport'
      TestCaseExecutionImport
    else
      TestCaseImport
    end
  end
end
