module TestCasesQueriesHelper

  def column_value(column, item, value)
    if item.is_a?(TestCase)
      case column.name
      when :id
        if item.test_plan
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
        if item.test_plan
          link_to item.name,
                  project_test_plan_test_case_url(project_id: item.project.identifier,
                                                  test_plan_id: item.test_plan.id,
                                                  id: item.id)
        else
          link_to item.name,
                  project_test_case_url(project_id: item.project.identifier,
                                        id: item.id)
        end
      else
        super
      end
    else
      raise ArgumentError
    end
  end
end
