class TestCaseExecution < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  belongs_to :issue
  belongs_to :test_plan
end
