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
      when :test_case
        link_to truncate(item.test_case.name),
                project_test_plan_test_case_url(project_id: item.project.identifier,
                                                test_plan_id: item.test_plan.id,
                                                test_case_id: item.test_case.id,
                                                id: item.test_case.id)
      when :test_plan
        link_to truncate(item.test_plan.name),
                project_test_plan_url(project_id: item.project.identifier,
                                      id: item.test_plan.id)
      when :result
        value ? l(:label_succeed) : l(:label_failure)
      when :comment
        truncate(value)
      when :scenario
        column_truncated_text(item.test_case.scenario)
      when :expected
        column_truncated_text(item.test_case.expected)
      else
        super
      end
    else
      raise ArgumentError
    end
  end
end
