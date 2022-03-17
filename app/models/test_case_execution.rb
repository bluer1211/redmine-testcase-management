class TestCaseExecution < ActiveRecord::Base
  include TestCaseManagement::InheritIssuePermissions

  belongs_to :user
  belongs_to :project
  belongs_to :issue
  belongs_to :test_plan
  belongs_to :test_case
  acts_as_attachable

  validates :result, inclusion: { in: [true, false] }
  validates :comment, presence: true
  validates :user, presence: true

  scope :visible, (lambda do |*args|
    joins(:project).
    where(TestCaseManagement::InheritIssuePermissions.visible_condition(args.shift || User.current, *args))
  end)

  def attachments_visible?(user=User.current)
    true
  end

  def attachments_editable?(user=User.current)
    true
  end

  def attachments_deletable?(user=User.current)
    true
  end
end
