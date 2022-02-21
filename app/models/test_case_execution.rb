class TestCaseExecution < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  belongs_to :issue
  belongs_to :test_plan
  belongs_to :test_case

  validates :result, presence: true
  validates :comment, presence: true
  validates :user, presence: true
end
