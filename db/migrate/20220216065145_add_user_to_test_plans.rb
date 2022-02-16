class AddUserToTestPlans < ActiveRecord::Migration[5.2]
  def change
    add_reference :test_plans, :user, foreign_key: { to_table: :users }
  end
end
