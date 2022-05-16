class TestCaseQuery < Query

  self.queried_class = TestCase
  self.view_permission = :view_issues

  self.available_columns = [
    QueryColumn.new(:id, :sortable => "#{TestCase.table_name}.id", :default_order => 'desc', :caption => '#', :frozen => true),
    QueryColumn.new(:name, :sortable => "#{TestCase.table_name}.name"),
    QueryColumn.new(:user, :sortable => "#{TestCase.table_name}.user_id"),
    QueryColumn.new(:environment, :sortable => "#{TestCase.table_name}.environment"),
=begin
    # FIXME: deactivate unstable feature
    QueryColumn.new(:latest_result, :sortable => "#{TestCaseExecution.table_name}.result"),
    QueryColumn.new(:latest_execution_date, :sortable => "#{TestCaseExecution.table_name}.execution_date"),
=end
    QueryColumn.new(:latest_result),
    QueryColumn.new(:latest_execution_date, :sortable => "latest_execution_date"),
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
    add_available_filter "latest_execution_date", :type => :date
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
=begin
    # FIXME: deactivate unstable feature
    unless filters["latest_result"].blank?
      conditions << sql_for_latest_result_field("result", filters["latest_result"][:operator], filters["latest_result"][:values], TestCaseExecution.table_name, "result")
    end
    unless filters["execution_date"].blank?
      conditions << sql_for_field("execution_date", filters["execution_date"][:operator], filters["execution_date"][:values], TestCaseExecution.table_name, "execution_date")
    end
=end
    conditions.join(" AND ")
  end

  def base_scope
    TestCase.visible
      .where(getTestCaseConditions)
=begin
      # deactivate this way because duplicated record may appear in TestCaseQuery.test_cases...
      .joins(<<-SQL
          LEFT JOIN (SELECT test_case_id, max(execution_date) as execution_date
          FROM test_case_executions GROUP BY test_case_id) AS latest_tce on latest_tce.test_case_id = test_cases.id
          LEFT JOIN test_case_executions on latest_tce.test_case_id = test_case_executions.test_case_id
          AND latest_tce.execution_date = test_case_executions.execution_date
SQL
            )
=end
  end

  # Specify selected columns by default
  def default_columns_names
    [:id, :name, :environment, :user, :latest_result, :latest_execution_date, :scenario, :expected]
  end

  def default_sort_criteria
    # Newer test case should be listed on top
    [['id', 'desc']]
  end

  def sort_clause
    if clause = sort_criteria.sort_clause(sortable_columns)
      clause.map {|c|
        nocase_sql = if ActiveRecord::Base.connection.adapter_name =~ /sqlite/i
                       nocase_columns = ["name", "environment", "scenario", "expected"].select { |col| c.start_with?("#{TestCase.table_name}.#{col}") }
                       unless nocase_columns.empty?
                         column = nocase_columns.first
                         if c.end_with?("ASC")
                           Arel.sql "#{TestCase.table_name}.#{column} COLLATE NOCASE ASC"
                         else
                           Arel.sql "#{TestCase.table_name}.#{column} COLLATE NOCASE DESC"
                         end
                       else
                         Arel.sql c
                       end
                     else
                       Arel.sql c
                     end
        nocase_sql
      }
    end
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
        .joins(:test_plans)
        .with_latest_result(options[:test_plan_id])
        .where(conditions.join(" AND "))
        .order(order_option)
        .limit(options[:limit])
        .offset(options[:offset])
    else
      base_scope
        .with_latest_result
        .order(order_option)
        .limit(options[:limit])
        .offset(options[:offset])
    end
  end

  def test_case_count(test_plan_id=nil, for_count=false)
    if test_plan_id
      base_scope
        .joins(:test_plans)
        .with_latest_result(test_plan_id, for_count)
        .count
    else
      base_scope
        .with_latest_result(nil, for_count)
        .count
    end
  end

  # override default statement for .result
  def sql_for_latest_result_field(field, operator, value)
    case operator
    when "="
      if value == ["true"]
        "result = '1'"
      else
        "result = '0'"
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

  # override default statement for .execution_date
  def sql_for_latest_execution_date_field(field, operator, value)
    is_custom_filter = false
    db_table = "tce"
    db_field = "execution_date"
    # See Redmine's query.
    case operator
    when "="
      sql = date_clause(db_table, db_field, parse_date(value.first), parse_date(value.first), is_custom_filter)
    when ">="
      sql = date_clause(db_table, db_field, parse_date(value.first), nil, is_custom_filter)
    when "<="
      sql = date_clause(db_table, db_field, nil, parse_date(value.first), is_custom_filter)
    when "><"
      sql = date_clause(db_table, db_field, parse_date(value.first), parse_date(value.last), is_custom_filter)
    when "><t-"
      # between today - n days and today
      sql = relative_date_clause(db_table, db_field, - value.first.to_i, 0, is_custom_filter)
    when ">t-"
      # >= today - n days
      sql = relative_date_clause(db_table, db_field, - value.first.to_i, nil, is_custom_filter)
    when "<t-"
      # <= today - n days
      sql = relative_date_clause(db_table, db_field, nil, - value.first.to_i, is_custom_filter)
    when "t-"
      # = n days in past
      sql = relative_date_clause(db_table, db_field, - value.first.to_i, - value.first.to_i, is_custom_filter)
    when "><t+"
      # between today and today + n days
      sql = relative_date_clause(db_table, db_field, 0, value.first.to_i, is_custom_filter)
    when ">t+"
      # >= today + n days
      sql = relative_date_clause(db_table, db_field, value.first.to_i, nil, is_custom_filter)
    when "<t+"
      # <= today + n days
      sql = relative_date_clause(db_table, db_field, nil, value.first.to_i, is_custom_filter)
    when "t+"
      # = today + n days
      sql = relative_date_clause(db_table, db_field, value.first.to_i, value.first.to_i, is_custom_filter)
    when "t"
      # = today
      sql = relative_date_clause(db_table, db_field, 0, 0, is_custom_filter)
    when "ld"
      # = yesterday
      sql = relative_date_clause(db_table, db_field, -1, -1, is_custom_filter)
    when "nd"
      # = tomorrow
      sql = relative_date_clause(db_table, db_field, 1, 1, is_custom_filter)
    when "w"
      # = this week
      first_day_of_week = l(:general_first_day_of_week).to_i
      day_of_week = User.current.today.cwday
      days_ago =
        if day_of_week >= first_day_of_week
          day_of_week - first_day_of_week
        else
          day_of_week + 7 - first_day_of_week
        end
      sql = relative_date_clause(db_table, db_field, - days_ago, - days_ago + 6, is_custom_filter)
    when "lw"
      # = last week
      first_day_of_week = l(:general_first_day_of_week).to_i
      day_of_week = User.current.today.cwday
      days_ago =
        if day_of_week >= first_day_of_week
          day_of_week - first_day_of_week
        else
          day_of_week + 7 - first_day_of_week
        end
      sql = relative_date_clause(db_table, db_field, - days_ago - 7, - days_ago - 1, is_custom_filter)
    when "l2w"
      # = last 2 weeks
      first_day_of_week = l(:general_first_day_of_week).to_i
      day_of_week = User.current.today.cwday
      days_ago =
        if day_of_week >= first_day_of_week
          day_of_week - first_day_of_week
        else
          day_of_week + 7 - first_day_of_week
        end
      sql = relative_date_clause(db_table, db_field, - days_ago - 14, - days_ago - 1, is_custom_filter)
    when "nw"
      # = next week
      first_day_of_week = l(:general_first_day_of_week).to_i
      day_of_week = User.current.today.cwday
      from =
        -(
        if day_of_week >= first_day_of_week
          day_of_week - first_day_of_week
        else
          day_of_week + 7 - first_day_of_week
        end
      ) + 7
      sql = relative_date_clause(db_table, db_field, from, from + 6, is_custom_filter)
    when "m"
      # = this month
      date = User.current.today
      sql = date_clause(db_table, db_field,
                        date.beginning_of_month, date.end_of_month,
                        is_custom_filter)
    when "lm"
      # = last month
      date = User.current.today.prev_month
      sql = date_clause(db_table, db_field,
                        date.beginning_of_month, date.end_of_month,
                        is_custom_filter)
    when "nm"
      # = next month
      date = User.current.today.next_month
      sql = date_clause(db_table, db_field,
                        date.beginning_of_month, date.end_of_month,
                        is_custom_filter)
    when "y"
      # = this year
      date = User.current.today
      sql = date_clause(db_table, db_field,
                        date.beginning_of_year, date.end_of_year,
                        is_custom_filter)
    when "!*"
      # not executed
      sql = "#{db_table}.#{db_field} IS NULL"
    when "*"
      # all
      sql = "1=1"
    else
      sql = sql_for_field(db_table, db_field, parse_date(value.first), parse_date(value.last), is_custom_filter)
    end
    sql
  end
end

