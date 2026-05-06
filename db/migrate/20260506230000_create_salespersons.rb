class CreateSalespersons < ActiveRecord::Migration[7.2]
  def change
    create_table :salespersons do |t|
      t.string  :name,            null: false
      t.string  :email
      t.string  :phone
      t.decimal :commission_rate, precision: 5, scale: 2, null: false, default: 0
      t.boolean :active,          null: false, default: true
      t.timestamps
    end

    add_column :organizations, :salesperson_id, :bigint
    add_index  :organizations, :salesperson_id
    add_foreign_key :organizations, :salespersons
  end
end
