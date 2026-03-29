class CreateMedicalRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :medical_records do |t|
      t.integer  :organization_id, null: false
      t.integer  :appointment_id,  null: false
      t.integer  :patient_id,      null: false
      t.integer  :doctor_id,       null: false
      t.decimal  :weight,          precision: 5, scale: 2
      t.decimal  :height,          precision: 5, scale: 2
      t.decimal  :temperature,     precision: 4, scale: 1
      t.text     :diagnosis
      t.text     :treatment
      t.text     :medications
      t.text     :notes
      t.date     :next_visit_date

      t.timestamps
    end

    add_index :medical_records, :organization_id
    add_index :medical_records, :appointment_id, unique: true
    add_index :medical_records, :patient_id
    add_index :medical_records, :doctor_id
  end
end
