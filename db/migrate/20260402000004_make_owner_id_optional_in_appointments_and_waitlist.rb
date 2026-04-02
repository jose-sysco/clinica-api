class MakeOwnerIdOptionalInAppointmentsAndWaitlist < ActiveRecord::Migration[7.2]
  def change
    change_column_null :appointments,     :owner_id, true
    change_column_null :waitlist_entries, :owner_id, true
  end
end
