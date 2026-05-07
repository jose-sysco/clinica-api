class CreatePrescriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :prescriptions do |t|
      t.integer  :organization_id,    null: false
      t.integer  :doctor_id,          null: false
      t.integer  :patient_id,         null: false
      t.integer  :appointment_id
      t.integer  :medical_record_id
      t.string   :verification_token, null: false
      t.string   :status,             null: false, default: "active"
      t.jsonb    :medications,        null: false, default: []
      t.text     :diagnosis
      t.text     :notes
      t.date     :issued_at,          null: false
      t.date     :valid_until

      t.timestamps
    end

    add_index :prescriptions, :organization_id
    add_index :prescriptions, :verification_token, unique: true
    add_index :prescriptions, [ :organization_id, :patient_id ]
    add_index :prescriptions, :medical_record_id
  end
end
