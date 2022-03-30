class TestPlan < ActiveRecord::Base
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

  scope :visible, (lambda do |*args|
    joins(:project).
    where(TestCaseManagement::InheritIssuePermissions.visible_condition(args.shift || User.current, *args))
  end)
end
