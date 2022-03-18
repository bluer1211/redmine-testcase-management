class TestCase < ActiveRecord::Base
  include TestCaseManagement::InheritIssuePermissions

  belongs_to :user
  belongs_to :project
  belongs_to :test_plan
  has_many :test_case_executions, dependent: :destroy
  acts_as_attachable

  validates :name, presence: true
  validates :scenario, presence: true
  validates :expected, presence: true
  validates :user, presence: true
  validates :environment, presence: true

  validates_associated :test_case_executions

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
