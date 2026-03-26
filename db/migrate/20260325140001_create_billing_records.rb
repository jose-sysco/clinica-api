class CreateBillingRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :billing_records do |t|
      t.references :organization, null: false, foreign_key: true
      t.date       :period,      null: false
      t.decimal    :amount_paid, precision: 10, scale: 2, null: false
      t.string     :currency,    null: false, default: "GTQ"
      t.text       :notes
      t.bigint     :recorded_by_id, null: false
      t.datetime   :recorded_at,    null: false

      t.timestamps
    end

    add_index :billing_records, [:organization_id, :period], unique: true
    add_foreign_key :billing_records, :users, column: :recorded_by_id
  end
end
