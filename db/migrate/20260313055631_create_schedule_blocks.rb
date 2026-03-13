class CreateScheduleBlocks < ActiveRecord::Migration[7.2]
  def change
    create_table :schedule_blocks do |t|
      t.integer  :organization_id, null: false
      t.integer  :doctor_id,       null: false
      t.datetime :start_datetime,  null: false
      t.datetime :end_datetime,    null: false
      t.string   :reason

      t.timestamps
    end

    add_index :schedule_blocks, :organization_id
    add_index :schedule_blocks, :doctor_id
    add_index :schedule_blocks, [:doctor_id, :start_datetime, :end_datetime]
  end
end