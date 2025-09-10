class CreateTestPlans < ActiveRecord::Migration[7.2]
  def change
    create_table :test_plans do |t|
      t.string :name
      t.datetime :begin_date
      t.datetime :end_date
      t.integer :estimated_bug
    end
  end
end
