class CreateWaitlistEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :waitlist_entries do |t|
      t.integer  :organization_id, null: false
      t.integer  :doctor_id,       null: false
      t.integer  :patient_id,      null: false
      t.integer  :owner_id,        null: false
      t.date     :preferred_date
      t.text     :notes
      t.integer  :status,          null: false, default: 0
      t.datetime :notified_at

      t.timestamps
    end

    add_index :waitlist_entries, [:organization_id, :doctor_id, :status]
    add_index :waitlist_entries, [:organization_id, :patient_id]
  end
end
