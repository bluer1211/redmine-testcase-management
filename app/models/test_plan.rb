class TestPlan < ActiveRecord::Base
  belongs_to :user
  belongs_to :issue_status
  has_many :test_case_executions
  has_many :test_cases
end
