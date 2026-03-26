class AddLimitsToPlanConfigurations < ActiveRecord::Migration[7.2]
  def change
    add_column :plan_configurations, :display_name,     :string
    add_column :plan_configurations, :max_doctors,      :integer,  comment: "null = ilimitado"
    add_column :plan_configurations, :max_patients,     :integer,  comment: "null = ilimitado"
    add_column :plan_configurations, :price_monthly_usd, :decimal, precision: 10, scale: 2, default: 0
  end
end
