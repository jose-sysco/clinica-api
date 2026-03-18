class AddClinicalFieldsToPatients < ActiveRecord::Migration[7.2]
  def change
    add_column :patients, :blood_type,            :string
    add_column :patients, :allergies,             :text
    add_column :patients, :chronic_conditions,    :text
    add_column :patients, :microchip_number,      :string
    add_column :patients, :reproductive_status,   :string
  end
end
