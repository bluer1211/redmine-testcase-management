module TestCaseManagement
  module QueriesHelperPatch
    def redirect_to_test_case_query(options)
      redirect_to project_test_cases_path
    end

    def redirect_to_test_plan_query(options)
      # FIXME: redirect to test plans list
      redirect_to project_test_cases_path(project_id: @project.identifier)
    end

    def redirect_to_test_case_execution_query(options)
      # FIXME: redirect to test case executions list
      redirect_to project_test_cases_path(project_id: @project.identifier)
    end
  end
end

ActiveSupport::Reloader.to_prepare do
  unless QueriesHelper.included_modules.include?(TestCaseManagement::QueriesHelperPatch)
    QueriesHelper.send(:include, TestCaseManagement::QueriesHelperPatch)
  end
end
