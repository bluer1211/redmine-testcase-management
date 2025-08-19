class AddTestPlanRefToTestCases < ActiveRecord::Migration[7.2]
  def change
    add_reference :test_cases, :test_plan, foreign_key: true
  end
end
