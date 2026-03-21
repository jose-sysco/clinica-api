class AddRecurrenceToAppointments < ActiveRecord::Migration[7.2]
  def change
    add_column :appointments, :recurrence_group_id, :string
    add_column :appointments, :recurrence_index,    :integer
    add_column :appointments, :recurrence_total,    :integer
    add_index  :appointments, :recurrence_group_id
  end
end
