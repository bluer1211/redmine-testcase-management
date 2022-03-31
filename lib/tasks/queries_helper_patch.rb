module TestCaseManagement
  module QueriesHelperPatch
    def redirect_to_test_case_query(options)
      redirect_to project_test_cases_path
    end
  end
end

ActiveSupport::Reloader.to_prepare do
  unless QueriesHelper.included_modules.include?(TestCaseManagement::QueriesHelperPatch)
    QueriesHelper.send(:include, TestCaseManagement::QueriesHelperPatch)
  end
end
