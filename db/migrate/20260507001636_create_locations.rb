class CreateLocations < ActiveRecord::Migration[7.2]
  def change
    create_table :locations do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.string  :name,    null: false
      t.string  :address
      t.string  :city
      t.string  :phone
      t.boolean :active,  default: true, null: false

      t.timestamps
    end

    add_reference :doctors,      :location, foreign_key: true, index: true
    add_reference :appointments, :location, foreign_key: true, index: true
  end
end
