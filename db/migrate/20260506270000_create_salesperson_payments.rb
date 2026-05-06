class CreateSalespersonPayments < ActiveRecord::Migration[7.2]
  def change
    create_table :salesperson_payments do |t|
      t.bigint     :salesperson_id, null: false
      t.date       :period,         null: false
      t.decimal    :amount,         precision: 10, scale: 2, null: false
      t.datetime   :paid_at
      t.bigint     :paid_by_id
      t.text       :notes

      t.timestamps
    end

    add_index :salesperson_payments, :salesperson_id
    add_index :salesperson_payments, :paid_by_id
    add_index :salesperson_payments, [ :salesperson_id, :period ], unique: true

    add_foreign_key :salesperson_payments, :salespersons
    add_foreign_key :salesperson_payments, :users, column: :paid_by_id
  end
end
