class TestCaseQuery < Query

  self.queried_class = TestCase
  self.view_permission = :view_issues

  self.available_columns = [
    QueryColumn.new(:id, :sortable => "#{TestCase.table_name}.id", :default_order => 'desc', :caption => '#', :frozen => true),
    QueryColumn.new(:name, :sortable => "#{TestCase.table_name}.name"),
    QueryColumn.new(:user, :sortable => "#{TestCase.table_name}.user_id"),
    QueryColumn.new(:environment, :sortable => "#{TestCase.table_name}.environment"),
    QueryColumn.new(:scenario, :sortable => "#{TestCase.table_name}.scenario"),
    QueryColumn.new(:expected, :sortable => "#{TestCase.table_name}.expected")
    # FIXME: missing status column
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
    conditions.join(" AND ")
  end

  def base_scope
    TestCase.visible.joins(:test_plans)
      .where(getTestCaseConditions)
  end

  # Specify selected columns by default
  def default_columns_names
    [:id, :name, :environment, :user, :scenario, :expected]
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
end
