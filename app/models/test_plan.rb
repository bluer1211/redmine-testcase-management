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

  attr_accessor :test_case_ids # for import

  safe_attributes(
    "project_id",
    "name",
    "issue_status_id",
    "user_id",
    "estimated_bug",
    "begin_date",
    "end_date",
    :if => lambda {|instance, user| instance.new_record? || instance.attributes_editable?(user)})

  def safe_attribute_names(user=nil)
    names = super
    if new_record?
      names |= %w(project_id)
    end
    names
  end

  scope :visible, (lambda do |*args|
    user = args.shift || User.current
    joins(:project).
    where(TestCaseManagement::InheritIssuePermissions.issue_visible_condition(user, *args)).
    where(TestCaseManagement::InheritIssuePermissions.visible_condition(user, :view_test_plans, *args))
  end)

  def visible?(user=User.current)
    issues_visible?(user) and user_permission?(user, :view_test_plans)
  end

  def attributes_editable?(user=User.current)
    user_permission?(user, :edit_test_plans)
  end

  def deletable?(user=User.current)
    user_permission?(user, :delete_test_plans)
  end
end
