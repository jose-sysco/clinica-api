class AddLastLoginIpToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :last_login_ip, :string
  end
end
