class FixScheduleUniquenessIndex < ActiveRecord::Migration[7.2]
  def change
    remove_index :schedules, name: "index_schedules_on_doctor_id_and_day_of_week"

    # One global schedule per doctor+day (location_id IS NULL)
    add_index :schedules, [:doctor_id, :day_of_week],
              unique: true,
              where: "location_id IS NULL",
              name: "idx_schedules_global_unique_per_day"

    # One location-specific schedule per doctor+day+location
    add_index :schedules, [:doctor_id, :day_of_week, :location_id],
              unique: true,
              where: "location_id IS NOT NULL",
              name: "idx_schedules_location_unique_per_day"
  end
end
