class TestCaseExecution < ActiveRecord::Base
  include Redmine::SafeAttributes
  include TestCaseManagement::SafeAttributes
  include TestCaseManagement::InheritIssuePermissions

  belongs_to :user
  belongs_to :project
  belongs_to :issue
  belongs_to :test_plan
  belongs_to :test_case
  acts_as_attachable

  validates :result, inclusion: { in: [true, false] }
  validates :user, presence: true
  validates :test_plan, presence: true
  validates :test_case, presence: true
  validates :execution_date, presence: true

  validate :owned_only_by_visible_user

  safe_attributes(
    "project_id",
    "name",
    "issue_id",
    "user_id",
    "test_case_id",
    "test_plan_id",
    "result",
    "comment",
    "execution_date",
    :if => lambda {|test_case_execution, user| test_case_execution.new_record? || test_case_execution.attributes_editable?(user)})

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

  def attachments_visible?(user=User.current)
    visible?(user)
  end

  def attachments_editable?(user=User.current)
    editable?(user)
  end

  def attachments_deletable?(user=User.current)
    deletable?(user)
  end
end
