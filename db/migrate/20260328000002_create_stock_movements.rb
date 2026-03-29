class CreateStockMovements < ActiveRecord::Migration[7.2]
  def change
    create_table :stock_movements do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :product,      null: false, foreign_key: true
      t.references :user,         null: false, foreign_key: true
      t.references :doctor,       null: true,  foreign_key: true
      t.references :medical_record, null: true, foreign_key: true

      t.integer :movement_type, null: false  # entry | exit | adjustment
      t.decimal :quantity,      null: false, precision: 10, scale: 2
      t.decimal :stock_before,  null: false, precision: 10, scale: 2
      t.decimal :stock_after,   null: false, precision: 10, scale: 2
      t.string  :lot_number
      t.date    :expiration_date
      t.text    :notes

      t.timestamps
    end

    add_index :stock_movements, :movement_type
    add_index :stock_movements, :expiration_date
  end
end
