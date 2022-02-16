class AddUserToTestplans < ActiveRecord::Migration[5.2]
  def change
    add_reference :testplans, :user, foreign_key: true
  end
end
