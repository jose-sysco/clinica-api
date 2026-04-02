class MakeOwnerIdOptionalInPatients < ActiveRecord::Migration[7.2]
  def change
    change_column_null :patients, :owner_id, true
  end
end
