module TestCaseExecutionsQueriesHelper

  def column_value(column, item, value)
    if item.is_a?(TestCaseExecution)
      case column.name
      when :id
        link_to item.id,
                project_test_plan_test_case_test_case_execution_url(project_id: item.project.identifier,
                                                                    test_plan_id: item.test_plan.id,
                                                                    test_case_id: item.test_case.id,
                                                                    id: item.id)
      when :result
        value ? l(:label_succeed) : l(:label_failure)
      else
        super
      end
    else
      raise ArgumentError
    end
  end
end
