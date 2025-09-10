class RemoveScheduledDateFromTestCases < ActiveRecord::Migration[7.2]
  def change
    remove_column :test_cases, :scheduled_date
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
