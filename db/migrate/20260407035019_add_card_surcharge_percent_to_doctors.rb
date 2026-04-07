class AddCardSurchargePercentToDoctors < ActiveRecord::Migration[7.2]
  def change
    add_column :doctors, :card_surcharge_percent, :decimal, precision: 5, scale: 2
  end
end
