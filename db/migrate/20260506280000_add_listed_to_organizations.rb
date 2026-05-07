class AddListedToOrganizations < ActiveRecord::Migration[7.2]
  def change
    add_column :organizations, :listed, :boolean, default: true, null: false
  end
end
