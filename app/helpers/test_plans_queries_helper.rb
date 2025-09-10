module TestPlansQueriesHelper

  def column_value(column, item, value)
    if item.is_a?(TestPlan)
      case column.name
      when :id
        link_to item.id,
                project_test_plan_url(project_id: item.project.identifier,
                                      id: item.id)
      when :name
        link_to item.name,
                project_test_plan_url(project_id: item.project.identifier,
                                      id: item.id)
      when :begin_date, :end_date
        if value
          yyyymmdd_date(value)
        else
          l(:label_none)
        end
      else
        super
      end
    elsif item.is_a?(TestCase)
      # For test cases which is bound to test plan
      case column.name
      when :id
        link_to item.id,
                project_test_plan_test_case_url(project_id: item.project.identifier,
                                                test_plan_id: @test_plan.id,
                                                id: item.id)
      when :name
        link_to item.name,
                project_test_plan_test_case_url(project_id: item.project.identifier,
                                                test_plan_id: @test_plan.id,
                                                id: item.id)
      when :latest_execution_date
        if value
          yyyymmdd_date(value)
        else
          l(:label_none)
        end
      when :latest_result
        unless value.nil?
          link_to value ? l(:label_succeed) : l(:label_failure),
                  project_test_plan_test_case_test_case_execution_url(project_id: item.project.identifier,
                                                                      test_plan_id: @test_plan.id,
                                                                      test_case_id: item.id,
                                                                      id: item.latest_execution_id)
        else
          l(:label_none)
        end
      when :scenario, :expected
        column_truncated_text(value, truncate_line: false)
      else
        super
      end
    else
      raise ArgumentError
    end
  end
end
