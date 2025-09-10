class AddUserToTestCaseExecutions < ActiveRecord::Migration[7.2]
  def change
    add_reference :test_case_executions, :user, foreign_key: true, type: :integer
  end
end
