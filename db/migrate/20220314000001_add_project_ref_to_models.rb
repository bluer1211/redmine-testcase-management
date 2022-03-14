class AddProjectRefToModels < ActiveRecord::Migration[5.2]
  def change
    add_reference :test_cases, :project, foreign_key: true
    add_reference :test_case_executions, :project, foreign_key: true
    add_reference :test_plans, :project, foreign_key: true
  end
end
