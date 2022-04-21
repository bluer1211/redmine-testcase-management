class TestCase < ActiveRecord::Base
  include Redmine::SafeAttributes
  include TestCaseManagement::SafeAttributes
  include TestCaseManagement::InheritIssuePermissions

  belongs_to :user
  belongs_to :project
  has_many :test_case_test_plans, dependent: :destroy
  has_many :test_plans, through: :test_case_test_plans
  has_many :test_case_executions, dependent: :destroy
  acts_as_attachable

  validates :name, presence: true
  validates :scenario, presence: true
  validates :expected, presence: true
  validates :user, presence: true
  validates :environment, presence: true
  validates :project, presence: true

  validates_associated :test_case_executions

  validate :owned_only_by_visible_user

  safe_attributes(
    "project_id",
    "user_id",
    "name",
    "environment",
    "scenario",
    "expected",
    :if => lambda {|instance, user| instance.new_record? || instance.attributes_editable?(user)})

  def safe_attribute_names(user=nil)
    names = super
    if new_record?
      names |= %w(project_id)
    end
    names
  end

  scope :visible, (lambda do |*args|
    joins(:project).
    where(TestCaseManagement::InheritIssuePermissions.visible_condition(args.shift || User.current, *args))
  end)

  scope :with_latest_result, (lambda do |test_plan_or_id=nil|
    test_plan_id = test_plan_or_id
    test_plan_id = test_plan_or_id.id if test_plan_or_id.is_a?(TestPlan)
    test_plan_id = nil unless test_plan_id.is_a?(Integer)

    scope = all
    conditions = {}
    if test_plan_id
      scope = scope.
        joins(:test_case_test_plans)
      conditions["test_case_test_plans.test_plan_id"] = test_plan_id
    end

    scope.
    joins(<<-"SQL"
      LEFT OUTER JOIN
        (SELECT *
           FROM (SELECT *,
                        ROW_NUMBER()
                          OVER (PARTITION BY test_case_id
                                ORDER BY execution_date DESC, id DESC)
                          AS row_number_per_test_case_id
                   FROM test_case_executions
                   #{ test_plan_id ? sanitize_sql_array(['WHERE test_plan_id = ?', test_plan_id]) : '' })
                 AS tce_with_row_number
          WHERE row_number_per_test_case_id = 1) AS tce
        ON tce.test_case_id = test_cases.id
        #{ test_plan_id ? 'AND tce.test_plan_id = test_case_test_plans.test_plan_id' : '' }
SQL
    ).
    select(<<-SQL
      test_cases.*,
      tce.id AS latest_execution_id,
      tce.result AS latest_result,
      tce.execution_date AS latest_execution_date
SQL
    ).
    where(conditions)
  end)

  class << self
    def find_with_latest_result(id, options={})
      with_latest_result(options[:test_plan] || options[:test_plan_id]).find(id)
    end
  end

  # attributes based on most recently executed result
  def latest_result
    value = attributes["latest_result"]
    if value.is_a?(Integer) # SQLite
      attributes["latest_result"] = value == 1
    else # PostgreSQL and others
      value
    end
  end

  def latest_execution_date
    value = attributes["latest_execution_date"]
    if value.is_a?(String) # SQLite
      attributes["latest_execution_date"] = Time.parse(value)
    else # PostgreSQL and others
      value
    end
  end

  def latest_test_case_execution
    if attributes["latest_execution_id"]
      TestCaseExecution.find(attributes["latest_execution_id"])
    else
      nil
    end
  end

  def test_case_executions_for(test_plan=self.test_plan)
    conditions = {test_case: self}
    if test_plan
      if test_plan.is_a?(TestPlan)
        conditions[:test_plan] = test_plan
      else
        conditions[:test_plan_id] = test_plan
      end
    end
    TestCaseExecution
      .where(conditions)
  end


  def attachments_visible?(user=User.current)
    visible?(user)
  end

  def attachments_editable?(user=User.current)
    editable?(user)
  end

  def attachments_deletable?(user=User.current)
    deletable?(user)
  end


  # Workaround for functional tests.
  # This should be removed after we completely migrate to test_plan-independent design.
  def test_plan
    test_plans.first
  end
end
