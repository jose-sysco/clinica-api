class AddOrgLimitOverrides < ActiveRecord::Migration[7.2]
  def change
    add_column :organizations, :max_doctors_override,  :integer
    add_column :organizations, :max_patients_override, :integer
  end
end
