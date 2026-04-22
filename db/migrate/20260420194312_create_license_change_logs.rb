class CreateLicenseChangeLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :license_change_logs do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :changed_by,   null: true,  foreign_key: { to_table: :users }
      t.jsonb      :changes,      null: false, default: {}
      t.text       :notes

      t.timestamps
    end

    add_index :license_change_logs, :created_at
  end
end
