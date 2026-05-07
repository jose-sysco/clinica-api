class RefactorDoctorLocations < ActiveRecord::Migration[7.2]
  def change
    remove_column :doctors, :location_id, :bigint

    create_table :doctor_locations do |t|
      t.references :doctor,   null: false, foreign_key: true, index: true
      t.references :location, null: false, foreign_key: true, index: true
      t.timestamps
    end
    add_index :doctor_locations, [:doctor_id, :location_id], unique: true

    add_reference :schedules, :location, foreign_key: true, index: true, null: true
  end
end
