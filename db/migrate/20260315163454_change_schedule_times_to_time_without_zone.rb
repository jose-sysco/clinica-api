class ChangeScheduleTimesToTimeWithoutZone < ActiveRecord::Migration[7.2]
  def up
    change_column :schedules, :start_time, :time, precision: nil
    change_column :schedules, :end_time,   :time, precision: nil
  end

  def down
    change_column :schedules, :start_time, :time
    change_column :schedules, :end_time,   :time
  end
end