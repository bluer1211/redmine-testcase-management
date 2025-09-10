class TestPlanQuery < Query

  self.queried_class = TestPlan
  self.view_permission = :view_issues

  self.available_columns = [
    QueryColumn.new(:id, :sortable => "#{TestPlan.table_name}.id", :default_order => 'desc', :caption => '#', :frozen => true),
    QueryColumn.new(:name, :sortable => "#{TestPlan.table_name}.name", :caption => :field_test_plan_name),
    QueryColumn.new(:issue_status, :sortable => "#{TestPlan.table_name}.issue_status_id", :caption => :field_issue_status),
    QueryColumn.new(:estimated_bug, :sortable => "#{TestPlan.table_name}.estimated_bug", :caption => :field_estimated_bug),
    QueryColumn.new(:user, :sortable => "#{TestPlan.table_name}.user_id", :caption => :field_user),
    QueryColumn.new(:begin_date, :sortable => "#{TestPlan.table_name}.begin_date", :caption => :field_begin_date),
    QueryColumn.new(:end_date, :sortable => "#{TestPlan.table_name}.end_date", :caption => :field_end_date),
    QueryColumn.new(:test_case_ids, :sortable => false, :caption => :field_test_case_ids, :groupable => false),
  ]

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= { }
  end

  def initialize_available_filters
    add_available_filter "name", :type => :text
    add_available_filter "begin_date", :type => :date
    add_available_filter "end_date", :type => :date
    add_available_filter "estimated_bug", :type => :integer
    add_available_filter(
      "user_id",
      :type => :list, :values => lambda { author_values }
    )
    add_available_filter(
      "issue_status_id",
      :type => :list_status, :values => lambda { issue_statuses_values }
    )
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup
    @available_columns
  end

  def available_display_types
    ['list']
  end

  def getTestPlanConditions
    conditions = [statement]
    unless filters["name"].blank?
      conditions << sql_for_field("name", filters["name"][:operator], filters["name"][:values], TestPlan.table_name, "name")
    end
    unless filters["begin_date"].blank?
      conditions << sql_for_field("begin_date", filters["begin_date"][:operator], filters["begin_date"][:values], TestPlan.table_name, "begin_date")
    end
    unless filters["end_date"].blank?
      conditions << sql_for_field("end_date", filters["end_date"][:operator], filters["end_date"][:values], TestPlan.table_name, "end_date")
    end
    unless filters["estimated_bug"].blank?
      conditions << sql_for_field("estimated_bug", filters["estimated_bug"][:operator], filters["estimated_bug"][:values], TestPlan.table_name, "estimated_bug")
    end
    unless filters["user_id"].blank?
      user_ids = filters["user_id"][:values]
      if user_ids.any? { |user| user == "me" }
        user_ids.delete("me")
        user_ids << User.current.id.to_s
      end
      conditions << sql_for_field("user", filters["user_id"][:operator], user_ids, TestPlan.table_name, "user_id")
    end
    conditions.join(" AND ")
  end

  def base_scope
    TestPlan.visible
      .where(getTestPlanConditions)
  end

  # Specify selected columns by default
  def default_columns_names
    [:id, :name, :issue_status, :estimated_bug, :user, :begin_date, :end_date, :test_case_ids]
  end

  def default_sort_criteria
    # Newer test plan should be listed on top
    [['id', 'desc']]
  end

  # Valid options:
  #   :test_plan_id :limit :offset
  def test_plans(options={})
    order_option = [sort_clause]
    base_scope
      .order(order_option)
      .limit(options[:limit])
      .offset(options[:offset])
  end

  def test_plan_count
    base_scope.count
  end

  # override issue_status_id
  def sql_for_issue_status_id_field(field, operator, value)
    case operator
    when "o"
      open_status_ids = IssueStatus.where(is_closed: false).pluck(:id)
      sql_for_field(field, "=", open_status_ids, TestPlan.table_name, "issue_status_id")
    when "c"
      closed_status_ids = IssueStatus.where(is_closed: true).pluck(:id)
      sql_for_field(field, "=", closed_status_ids, TestPlan.table_name, "issue_status_id")
    when "*"
      all_status_ids = IssueStatus.all.pluck(:id)
      sql_for_field(field, "=", all_status_ids, TestPlan.table_name, "issue_status_id")
    else
      sql_for_field(field, operator, value, TestPlan.table_name, "issue_status_id")
    end
  end
end
