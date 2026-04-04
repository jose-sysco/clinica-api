class AddRegistrationIpToOrganizations < ActiveRecord::Migration[7.2]
  def change
    add_column :organizations, :registration_ip, :string
  end
end
