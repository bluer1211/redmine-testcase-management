class AddTestProjectRefToTestCaseExecutions < ActiveRecord::Migration[7.2]
  def change
    add_reference :test_case_executions, :test_project, foreign_key: true
  end
end
