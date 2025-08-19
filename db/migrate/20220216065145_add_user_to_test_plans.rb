class AddUserToTestPlans < ActiveRecord::Migration[7.2]
  def change
    add_reference :test_plans, :user, foreign_key: { to_table: :users }, type: :integer
  end
end
