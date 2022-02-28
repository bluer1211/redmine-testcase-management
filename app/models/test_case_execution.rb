class TestCaseExecution < ActiveRecord::Base
  belongs_to :user, foreign_key: true
  belongs_to :test_project, foreign_key: true
  belongs_to :issue, foreign_key: true
  belongs_to :test_plan, foreign_key: true
  belongs_to :test_case, foreign_key: true
  acts_as_attachable

  validates :result, presence: true
  validates :comment, presence: true
  validates :user, presence: true
end
