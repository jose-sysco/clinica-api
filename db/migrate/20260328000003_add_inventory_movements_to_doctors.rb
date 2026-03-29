class AddInventoryMovementsToDoctors < ActiveRecord::Migration[7.2]
  def change
    add_column :doctors, :inventory_movements, :boolean, null: false, default: false
  end
end
