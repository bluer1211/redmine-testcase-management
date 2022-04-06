module TestCasesQueriesHelper

  def column_value(column, item, value)
    if item.is_a?(TestCase)
      case column.name
      when :id
        if @test_plan_given and item.test_plan
          link_to item.id,
                project_test_plan_test_case_url(project_id: item.project.identifier,
                                                test_plan_id: item.test_plan.id,
                                                id: item.id)
        else
          link_to item.id,
                  project_test_case_url(project_id: item.project.identifier,
                                        id: item.id)
        end
      when :name
        if @test_plan_given and item.test_plan
          link_to item.name,
                  project_test_plan_test_case_url(project_id: item.project.identifier,
                                                  test_plan_id: item.test_plan.id,
                                                  id: item.id)
        else
          link_to item.name,
                  project_test_case_url(project_id: item.project.identifier,
                                        id: item.id)
        end
      when :latest_result
        if value
          link_to value.result ? l(:label_succeed) : l(:label_failure),
                  project_test_plan_test_case_test_case_execution_url(project_id: item.project.identifier,
                                                                      test_plan_id: item.test_plan.id,
                                                                      test_case_id: item.id,
                                                                      id: item.test_case_executions.order("execution_date desc").first.id)
        else
          l(:label_none)
        end
      when :execution_date
        if value
          # value is TestCaseExecution
          link_to yyyymmdd_date(value.execution_date),
                  project_test_plan_test_case_test_case_execution_url(project_id: item.project.identifier,
                                                                      test_plan_id: item.test_plan.id,
                                                                      test_case_id: item.id,
                                                                      id: value.id)
        else
          l(:label_none)
        end
      else
        super
      end
    else
      raise ArgumentError
    end
  end
end
