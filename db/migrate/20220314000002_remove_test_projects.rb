class RemoveTestProjects < ActiveRecord::Migration[5.2]
  def change
    remove_reference :test_cases, :test_project
    remove_reference :test_case_executions, :test_project
    remove_reference :test_plans, :test_project
    drop_table :test_projects
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
