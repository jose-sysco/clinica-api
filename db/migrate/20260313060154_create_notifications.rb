class CreateNotifications < ActiveRecord::Migration[7.2]
  def change
    create_table :notifications do |t|
      t.integer  :organization_id,    null: false
      t.integer  :user_id,            null: false
      t.integer  :appointment_id,     null: false
      t.integer  :notification_type,  null: false, default: 0
      t.integer  :channel,            null: false, default: 0
      t.integer  :status,             null: false, default: 0
      t.datetime :sent_at
      t.datetime :read_at
      t.text     :message,            null: false

      t.timestamps
    end

    add_index :notifications, :organization_id
    add_index :notifications, :user_id
    add_index :notifications, :appointment_id
    add_index :notifications, [ :user_id, :status ]
    add_index :notifications, [ :user_id, :read_at ]
  end
end
