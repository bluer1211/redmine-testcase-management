class AddTestPlanToTestCaseExecutions < ActiveRecord::Migration[5.2]
  def change
    add_reference :test_case_executions, :test_plan, foreign_key: true
  end
end
