class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.references :organization, null: false, foreign_key: true
      t.string  :name,           null: false
      t.string  :description
      t.string  :category
      t.string  :unit,           null: false, default: "unidad"
      t.decimal :current_stock,  null: false, default: 0, precision: 10, scale: 2
      t.decimal :min_stock,      null: false, default: 0, precision: 10, scale: 2
      t.string  :sku
      t.boolean :active,         null: false, default: true

      t.timestamps
    end

    add_index :products, [ :organization_id, :name ]
    add_index :products, [ :organization_id, :active ]
  end
end
