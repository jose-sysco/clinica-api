class CreateWeightRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :weight_records do |t|
      t.integer :organization_id, null: false
      t.integer :patient_id,      null: false
      t.decimal :weight,          null: false, precision: 6, scale: 2
      t.date    :recorded_on,     null: false
      t.text    :notes

      t.timestamps
    end

    add_index :weight_records, :patient_id
    add_index :weight_records, :organization_id
    add_index :weight_records, [ :patient_id, :recorded_on ]
  end
end
