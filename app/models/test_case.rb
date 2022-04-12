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

  safe_attributes(
    "project_id'",
    "user_id",
    "name",
    "environment",
    "scenario",
    "expected",
    :if => lambda {|test_case, user| test_case.new_record? || test_case.attributes_editable?(user)})

  scope :visible, (lambda do |*args|
    joins(:project).
    where(TestCaseManagement::InheritIssuePermissions.visible_condition(args.shift || User.current, *args))
  end)

  #self.test_case_executions.order("execution_date desc").first
  has_one :latest_result, -> {
    where(<<~SQL
    NOT EXISTS (
      SELECT 1 FROM test_case_executions AS tce
      WHERE test_case_executions.execution_date < tce.execution_date
      AND test_case_executions.test_case_id = tce.test_case_id
      AND tce.execution_date IS NOT NULL
    )
SQL
         )
  }, class_name: :TestCaseExecution

  has_one :execution_date, -> {
    where(<<~SQL
    NOT EXISTS (
      SELECT 1 FROM test_case_executions AS tce
      WHERE test_case_executions.execution_date < tce.execution_date
      AND test_case_executions.test_case_id = tce.test_case_id
      AND tce.execution_date IS NOT NULL
    )
SQL
         )
  }, class_name: :TestCaseExecution

  def latest_effective_test_case_execution(test_plan=nil)
    test_case_executions_for(test_plan)
      .where.not(execution_date: nil)
      .order("execution_date DESC")
      .first
  end

  def test_case_executions_for(test_plan=nil)
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
