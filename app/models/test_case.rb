class TestCase < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  belongs_to :issue_status
  has_many :test_case_executions
end
