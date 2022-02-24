class TestCaseExecution < ActiveRecord::Base
  belongs_to :user
  belongs_to :test_project
  belongs_to :issue
  belongs_to :test_plan
  belongs_to :test_case
  acts_as_attachable

  validates :result, presence: true
  validates :comment, presence: true
  validates :user, presence: true
end
