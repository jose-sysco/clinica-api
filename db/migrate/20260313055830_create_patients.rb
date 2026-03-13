class CreatePatients < ActiveRecord::Migration[7.2]
  def change
    create_table :patients do |t|
      t.integer :organization_id, null: false
      t.integer :owner_id,        null: false
      t.string  :name,            null: false
      t.integer :patient_type,    null: false, default: 0
      t.string  :species
      t.string  :breed
      t.integer :gender,          null: false, default: 0
      t.date    :birthdate
      t.decimal :weight,          precision: 5, scale: 2
      t.text    :notes
      t.integer :status,          null: false, default: 0

      t.timestamps
    end

    add_index :patients, :organization_id
    add_index :patients, :owner_id
    add_index :patients, [:organization_id, :status]
  end
end