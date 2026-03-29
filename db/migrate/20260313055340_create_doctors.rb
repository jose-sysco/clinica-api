class CreateDoctors < ActiveRecord::Migration[7.2]
  def change
    create_table :doctors do |t|
      t.integer :organization_id, null: false
      t.integer :user_id,         null: false
      t.string  :specialty,       null: false
      t.string  :license_number
      t.text    :bio
      t.integer :consultation_duration, default: 30, null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :doctors, :organization_id
    add_index :doctors, :user_id
    add_index :doctors, :license_number, unique: true
  end
end
