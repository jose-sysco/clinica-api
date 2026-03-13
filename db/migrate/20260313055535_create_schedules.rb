class CreateSchedules < ActiveRecord::Migration[7.2]
  def change
    create_table :schedules do |t|
      t.integer :organization_id, null: false
      t.integer :doctor_id,       null: false
      t.integer :day_of_week,     null: false
      t.time    :start_time,      null: false
      t.time    :end_time,        null: false
      t.boolean :is_active,       default: true, null: false

      t.timestamps
    end

    add_index :schedules, :organization_id
    add_index :schedules, :doctor_id
    add_index :schedules, [:doctor_id, :day_of_week], unique: true
  end
end