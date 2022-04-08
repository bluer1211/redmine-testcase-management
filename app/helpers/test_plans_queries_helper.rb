module TestPlansQueriesHelper

  def column_value(column, item, value)
    if item.is_a?(TestPlan)
      case column.name
      when :id
        link_to item.id,
              project_test_case_url(project_id: item.project.identifier,
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
    else
      raise ArgumentError
    end
  end
end
