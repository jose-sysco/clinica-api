class RenameLicenseChangeLogChangesColumn < ActiveRecord::Migration[7.2]
  def change
    rename_column :license_change_logs, :changes, :change_data
  end
end
