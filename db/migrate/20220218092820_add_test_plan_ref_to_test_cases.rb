class AddTestPlanRefToTestCases < ActiveRecord::Migration[5.2]
  def change
    add_reference :test_cases, :test_plan, foreign_key: true
  end
end
