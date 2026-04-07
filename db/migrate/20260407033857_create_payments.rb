class CreatePayments < ActiveRecord::Migration[7.2]
  def change
    create_table :payments do |t|
      t.integer  :organization_id, null: false
      t.references :appointment,  null: false, foreign_key: true
      t.references :recorded_by,  null: false, foreign_key: { to_table: :users }
      t.decimal  :amount,          null: false, precision: 10, scale: 2
      t.integer  :payment_method,  null: false, default: 0
      t.string   :notes

      t.timestamps
    end

    add_index :payments, :organization_id
    add_index :payments, [ :organization_id, :appointment_id ]
  end
end
