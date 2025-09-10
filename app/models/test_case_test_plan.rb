class TestCaseTestPlan < ActiveRecord::Base
  belongs_to :test_case
  belongs_to :test_plan
end
