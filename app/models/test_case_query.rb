class TestCaseQuery < Query

  self.queried_class = TestCase
  self.view_permission = :view_issues

  self.available_columns = [
    QueryColumn.new(:id, :sortable => "#{TestCase.table_name}.id", :default_order => 'desc', :caption => '#', :frozen => true),
    QueryColumn.new(:name, :sortable => "#{TestCase.table_name}.name"),
    QueryColumn.new(:user, :sortable => "#{TestCase.table_name}.user_id"),
    QueryColumn.new(:environment, :sortable => "#{TestCase.table_name}.environment"),
    QueryColumn.new(:latest_result, :sortable => "#{TestCaseExecution.table_name}.result"),
    QueryColumn.new(:scenario, :sortable => "#{TestCase.table_name}.scenario"),
    QueryColumn.new(:expected, :sortable => "#{TestCase.table_name}.expected")
  ]

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= { }
  end

  def initialize_available_filters
    add_available_filter "name", :type => :text
    add_available_filter "environment", :type => :text
    add_available_filter(
      "user_id",
      :type => :list, :values => lambda { author_values }
    )
    add_available_filter(
      "latest_result",
      :type => :list, :values => lambda { [[l(:label_succeed), true], [l(:label_failure), false]] }
    )
    add_available_filter "scenario", :type => :text
    add_available_filter "expected", :type => :text
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup
    @available_columns
  end

  def available_display_types
    ['list']
  end

  def getTestCaseConditions
    conditions = [statement]
    unless filters["name"].blank?
      conditions << sql_for_field("name", filters["name"][:operator], filters["name"][:values], TestCase.table_name, "name")
    end
    unless filters["user_id"].blank?
      user_ids = filters["user_id"][:values]
      if user_ids.any? { |user| user == "me" }
        user_ids.delete("me")
        user_ids << User.current.id.to_s
      end
      conditions << sql_for_field("user", filters["user_id"][:operator], user_ids, TestCase.table_name, "user_id")
    end
    unless filters["scenario"].blank?
      conditions << sql_for_field("scenario", filters["scenario"][:operator], filters["scenario"][:values], TestCase.table_name, "scenario")
    end
    unless filters["expected"].blank?
      conditions << sql_for_field("expected", filters["expected"][:operator], filters["expected"][:values], TestCase.table_name, "expected")
    end
    unless filters["last_result"].blank?
      conditions << sql_for_last_result_field("result", filters["last_result"][:operator], filters["last_result"][:values], TestCaseExecution.table_name, "result")
    end
    conditions.join(" AND ")
  end

  def base_scope
    TestCase.visible.joins(:test_plans)
      .joins(<<-SQL
          INNER JOIN (SELECT test_case_id, max(execution_date) as execution_date
          FROM test_case_executions GROUP BY test_case_id) AS latest_tce on latest_tce.test_case_id = test_cases.id
          INNER JOIN test_case_executions on latest_tce.test_case_id = test_case_executions.test_case_id
           AND latest_tce.execution_date = test_case_executions.execution_date
SQL
            )
      .where(getTestCaseConditions)
  end

  # Specify selected columns by default
  def default_columns_names
    [:id, :name, :environment, :user, :latest_result, :scenario, :expected]
  end

  def default_sort_criteria
    # Newer test case should be listed on top
    [['id', 'desc']]
  end

  # Valid options:
  #   :test_plan_id :test_case_id :limit :offset
  def test_cases(options={})
    order_option = [sort_clause]
    conditions = [
      sql_for_field("id", "=", [options[:test_plan_id]], TestPlan.table_name, 'id')
    ]
    if options[:test_plan_id]
      base_scope
        .where(conditions.join(" AND "))
        .order(order_option)
        .limit(options[:limit])
        .offset(options[:offset])
    else
      TestCase.visible
        .where(getTestCaseConditions)
        .order(order_option)
        .limit(options[:limit])
        .offset(options[:offset])
    end
  end

  def test_case_count
    base_scope.count
  end

  # override default statement for .result
  def sql_for_latest_result_field(field, operator, value)
    case operator
    when "="
      if value == ["true"]
        "result = 't'"
      else
        "result = 'f'"
      end
    when "!"
      if value == ["true"]
        "result IS NOT true"
      else
        "result IS NOT false"
      end
    else
      "1=0"
    end
  end
end

