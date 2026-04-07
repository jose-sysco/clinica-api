class AddConsultationFeeToDoctors < ActiveRecord::Migration[7.2]
  def change
    add_column :doctors, :consultation_fee, :decimal, precision: 10, scale: 2
  end
end
