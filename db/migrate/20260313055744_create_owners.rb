class CreateOwners < ActiveRecord::Migration[7.2]
  def change
    create_table :owners do |t|
      t.integer :organization_id, null: false
      t.integer :user_id
      t.string  :first_name,      null: false
      t.string  :last_name,       null: false
      t.string  :email
      t.string  :phone,           null: false
      t.string  :address
      t.string  :identification

      t.timestamps
    end

    add_index :owners, :organization_id
    add_index :owners, :user_id
    add_index :owners, [ :organization_id, :identification ], unique: true
    add_index :owners, [ :organization_id, :email ],          unique: true
  end
end
