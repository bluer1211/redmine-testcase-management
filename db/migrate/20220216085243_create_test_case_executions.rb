class CreateTestCaseExecutions < ActiveRecord::Migration[5.2]
  def change
    create_table :test_case_executions do |t|
      t.boolean :result, null: false, default: false
      t.text :comment
      t.datetime :execution_date
    end
  end
end
