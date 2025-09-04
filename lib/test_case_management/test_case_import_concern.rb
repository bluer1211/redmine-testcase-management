module TestCaseManagement
  module TestCaseImportConcern
    extend ActiveSupport::Concern

    included do
      before_action :ensure_test_case_import_project_context, only: [:settings, :mapping, :run, :show]
    end

    private

    def ensure_test_case_import_project_context
      # 處理所有測試案例相關的匯入類型
      return unless @import.is_a?(TestCaseImport) || @import.is_a?(TestPlanImport) || @import.is_a?(TestCaseExecutionImport)
      
      # 如果沒有 @project，嘗試從 import 對象獲取
      unless @project
        @project = @import.project
      end
      
      # 如果還是沒有，嘗試從 settings 獲取
      unless @project && @import.settings && @import.settings['project_id']
        project_id = @import.settings['project_id']
        if project_id
          @project = if project_id.to_s.match?(/^\d+$/)
                       Project.find_by(id: project_id.to_i)
                     else
                       Project.find_by(identifier: project_id.to_s)
                     end
        end
      end
      
      # 如果還是沒有，嘗試從自身的 project_id 獲取
      unless @project && @import.project_id
        if @import.project_id
          @project = Project.find_by(id: @import.project_id)
        end
      end
    end
  end
end
