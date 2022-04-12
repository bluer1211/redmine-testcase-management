class TestPlan < ActiveRecord::Base
  include Redmine::SafeAttributes
  include TestCaseManagement::SafeAttributes
  include TestCaseManagement::InheritIssuePermissions

  belongs_to :user
  belongs_to :issue_status
  belongs_to :project
  has_many :test_case_test_plans, dependent: :destroy
  has_many :test_cases, through: :test_case_test_plans
  has_many :test_case_executions, dependent: :destroy

  validates :name, presence: true
  validates :user, presence: true
  validates :issue_status, presence: true
  validates :project, presence: true

  validates_associated :test_cases
  validates_associated :test_case_executions

  validates_length_of :name, :maximum => 255

  validate :owned_only_by_visible_user

  safe_attributes(
    "project_id'",
    "name",
    "issue_status_id",
    "user_id",
    "estimated_bug",
    "begin_date",
    "end_date",
    :if => lambda {|test_plan, user| test_plan.new_record? || test_plan.attributes_editable?(user)})

  scope :visible, (lambda do |*args|
    joins(:project).
    where(TestCaseManagement::InheritIssuePermissions.visible_condition(args.shift || User.current, *args))
  end)
end
