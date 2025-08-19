class AddTestPlansRefToTestCases < ActiveRecord::Migration[7.2]
  def change
    remove_reference :test_cases, :test_plan
    create_table :test_case_test_plans do |t|
      t.references :test_case, foreign_key: true
      t.references :test_plan, foreign_key: true
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
