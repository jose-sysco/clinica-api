class AddPrimaryColorToOrganizations < ActiveRecord::Migration[7.2]
  def change
    add_column :organizations, :primary_color, :string
  end
end
