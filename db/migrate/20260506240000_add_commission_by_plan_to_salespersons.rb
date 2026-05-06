class AddCommissionByPlanToSalespersons < ActiveRecord::Migration[7.2]
  def change
    add_column :salespersons, :commission_by_plan, :jsonb, default: {}, null: false
    change_column_null    :salespersons, :commission_rate, true
    change_column_default :salespersons, :commission_rate, nil
  end
end
