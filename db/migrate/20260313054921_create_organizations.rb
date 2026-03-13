class CreateOrganizations < ActiveRecord::Migration[7.2]
  def change
    create_table :organizations do |t|
      t.string :name,       null: false
      t.string :slug,       null: false
      t.string :subdomain,  null: false
      t.string :email,      null: false
      t.string :phone
      t.string :address
      t.string :city
      t.string :country
      t.string :timezone,   default: "UTC", null: false
      t.string :logo
      t.integer :clinic_type, default: 0, null: false
      t.integer :status,      default: 0, null: false

      t.timestamps
    end

    add_index :organizations, :slug,      unique: true
    add_index :organizations, :subdomain, unique: true
    add_index :organizations, :email,     unique: true
  end
end