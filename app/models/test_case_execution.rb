class TestCaseExecution < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  belongs_to :issue
  belongs_to :test_plan
  belongs_to :test_case
  acts_as_attachable

  validates :result, inclusion: { in: [true, false] }
  validates :comment, presence: true
  validates :user, presence: true

  def editable?
    true
  end

  def deletable?
    true
  end

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
