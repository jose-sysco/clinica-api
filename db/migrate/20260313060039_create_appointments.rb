class CreateAppointments < ActiveRecord::Migration[7.2]
  def change
    create_table :appointments do |t|
      t.integer  :organization_id,      null: false
      t.integer  :doctor_id,            null: false
      t.integer  :patient_id,           null: false
      t.integer  :owner_id,             null: false
      t.datetime :scheduled_at,         null: false
      t.datetime :ends_at,              null: false
      t.integer  :status,               null: false, default: 0
      t.integer  :appointment_type,     null: false, default: 0
      t.text     :reason,               null: false
      t.text     :notes
      t.integer  :cancelled_by
      t.text     :cancellation_reason
      t.datetime :confirmed_at

      t.timestamps
    end

    add_index :appointments, :organization_id
    add_index :appointments, :doctor_id
    add_index :appointments, :patient_id
    add_index :appointments, :owner_id
    add_index :appointments, [:doctor_id, :scheduled_at, :ends_at]
    add_index :appointments, [:organization_id, :status]
    add_index :appointments, [:doctor_id, :status]
  end
end