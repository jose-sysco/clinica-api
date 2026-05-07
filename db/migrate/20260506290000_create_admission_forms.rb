class CreateAdmissionForms < ActiveRecord::Migration[7.2]
  def change
    create_table :admission_forms do |t|
      t.integer    :organization_id, null: false
      t.references :appointment,     null: false, foreign_key: true, index: { unique: true }
      t.string     :token,           null: false
      t.string     :patient_name
      t.date       :patient_dob
      t.text       :allergies
      t.text       :current_medications
      t.text       :medical_history
      t.text       :notes
      t.datetime   :submitted_at

      t.timestamps
    end

    add_index :admission_forms, :organization_id
    add_index :admission_forms, :token, unique: true
  end
end
