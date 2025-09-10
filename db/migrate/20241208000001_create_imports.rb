class CreateImports < ActiveRecord::Migration[7.0]
  def change
    create_table :imports do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.string :type, null: false
      t.text :settings
      t.text :mapping
      t.timestamps
    end

    add_index :imports, [:user_id, :project_id]
    add_index :imports, :type
  end
end
