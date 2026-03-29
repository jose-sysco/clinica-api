class AddFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :organization_id, :integer, null: false
    add_index  :users, :organization_id
    add_column :users, :first_name, :string, null: false
    add_column :users, :last_name,  :string, null: false
    add_column :users, :phone,  :string
    add_column :users, :role,   :integer, default: 0, null: false
    add_column :users, :status, :integer, default: 0, null: false
    add_column :users, :avatar, :string
  end
end
