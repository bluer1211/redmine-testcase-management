class AddIssueToTestCaseExecutions < ActiveRecord::Migration[5.2]
  def change
    add_reference :test_case_executions, :issue, foreign_key: true
  end
end
