class AddProjectRefToModels < ActiveRecord::Migration[7.2]
  def change
    add_reference :test_cases, :project, foreign_key: true, type: :integer
    add_reference :test_case_executions, :project, foreign_key: true, type: :integer
    add_reference :test_plans, :project, foreign_key: true, type: :integer
  end
end
