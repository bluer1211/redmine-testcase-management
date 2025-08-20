class TestCaseExecutionQuery < Query

  self.queried_class = TestCaseExecution
  self.view_permission = :view_issues

  self.available_columns = [
    QueryColumn.new(:id, :sortable => "#{TestCaseExecution.table_name}.id", :default_order => 'desc', :caption => '#', :frozen => true),
    QueryColumn.new(:test_case, :sortable => "#{TestCaseExecution.table_name}.test_case_id", :caption => :field_test_case),
    QueryColumn.new(:test_plan, :sortable => "#{TestCaseExecution.table_name}.test_plan_id", :caption => :field_test_plan),
    QueryColumn.new(:result, :sortable => "#{TestCaseExecution.table_name}.result", :caption => :field_result),
    QueryColumn.new(:user, :sortable => "#{TestCaseExecution.table_name}.user_id", :caption => :field_user),
    QueryColumn.new(:issue, :sortable => "#{TestCaseExecution.table_name}.issue_id", :caption => :field_issue),
    QueryColumn.new(:comment, :sortable => "#{TestCaseExecution.table_name}.comment", :caption => :field_comment),
    QueryColumn.new(:scenario, :sortable => "#{TestCase.table_name}.scenario", :caption => :field_scenario),
    QueryColumn.new(:expected, :sortable => "#{TestCase.table_name}.expected", :caption => :field_expected),
    TimestampQueryColumn.new(:execution_date, :sortable => "#{TestCaseExecution.table_name}.execution_date", :default_order => 'desc', :caption => :field_execution_date)
  ]

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= { }
  end

  def initialize_available_filters
    add_available_filter "test_plan", :type => :text
    add_available_filter "test_case", :type => :text
    add_available_filter(
      "user_id",
      :type => :list, :values => lambda { author_values }
    )
    add_available_filter "result", :type => :list, :values => lambda { [[l(:label_succeed), 1], [l(:label_failure), 0]] }
    add_available_filter "comment", :type => :text
    add_available_filter "execution_date", :type => :date
    add_available_filter "issue_id", :type => :integer, :label => :label_issue
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

  def getTestCaseExecutionConditions
    conditions = [statement]
    unless filters["result"].blank?
      conditions << sql_for_field("result", filters["result"][:operator], filters["result"][:values], TestCaseExecution.table_name, 'result')
    end
    unless filters["user_id"].blank?
      user_ids = filters["user_id"][:values]
      if user_ids.any? { |user| user == "me" }
        user_ids.delete("me")
        user_ids << User.current.id.to_s
      end
      conditions << sql_for_field("user", filters["user_id"][:operator], user_ids, TestCaseExecution.table_name, 'user_id')
    end
    unless filters["execution_date"].blank?
      conditions << sql_for_field("execution_date", filters["execution_date"][:operator], filters["execution_date"][:values], TestCaseExecution.table_name, 'execution_date')
    end
    unless filters["comment"].blank?
      conditions << sql_for_field("comment", filters["comment"][:operator], filters["comment"][:values], TestCaseExecution.table_name, 'comment')
    end
    unless filters["issue_id"].blank?
      conditions << sql_for_field("issue_id", filters["issue_id"][:operator], filters["issue_id"][:values], TestCaseExecution.table_name, 'issue_id')
    end
    conditions.join(" AND ")
  end

  def base_scope
    TestCaseExecution.visible.joins(:test_case, :test_plan)
      .where(getTestCaseExecutionConditions)
  end

  # Specify selected columns by default
  def default_columns_names
    [:id, :test_plan, :test_case, :scenario, :expected, :result, :user, :execution_date, :comment, :issue]
  end

  def default_sort_criteria
    # Newer test case execution should be listed on top
    [['id', 'test_case', 'test_plan', 'desc']]
  end

  # Valid options:
  #   :test_plan_id :test_case_id :limit :offset
  def test_case_executions(options={})
    order_option = [sort_clause]
    conditions = []
    if options[:test_plan_id]
      conditions << sql_for_field("id", "=", [options[:test_plan_id]], TestPlan.table_name, 'id')
    end
    if options[:test_case_id]
      conditions << sql_for_field("id", "=", [options[:test_case_id]], TestCase.table_name, 'id')
    end
    base_scope()
      .where(conditions.join(" AND "))
      .order(order_option)
      .limit(options[:limit])
      .offset(options[:offset])
      .select("test_case_executions.*, test_cases.scenario, test_cases.expected")
  end

  def test_case_execution_count
    base_scope.count
  end

  # override default statement for test_plan
  def sql_for_test_plan_field(field, operator, value)
    sql_for_field("test_plan", filters["test_plan"][:operator], filters["test_plan"][:values], TestPlan.table_name, 'name')
  end

  # override default statement for test_case
  def sql_for_test_case_field(field, operator, value)
    sql_for_field("test_case", filters["test_case"][:operator], filters["test_case"][:values], TestCase.table_name, 'name')
  end

  # override default statement for scenario
  def sql_for_scenario_field(field, operator, value)
    sql_for_field("scenario", filters["scenario"][:operator], filters["scenario"][:values], TestCase.table_name, 'scenario')
  end

  # override default statement for expected
  def sql_for_expected_field(field, operator, value)
    sql_for_field("expected", filters["expected"][:operator], filters["expected"][:values], TestCase.table_name, 'expected')
  end
end
