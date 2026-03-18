class CreatePlanConfigurations < ActiveRecord::Migration[7.2]
  def change
    create_table :plan_configurations do |t|
      t.integer :plan,          null: false
      t.string  :name,          null: false
      t.decimal :price_monthly, precision: 10, scale: 2, default: 0
      t.text    :features,      null: false, default: '[]'
      t.timestamps
    end
    add_index :plan_configurations, :plan, unique: true
  end
end
