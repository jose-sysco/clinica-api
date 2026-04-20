class AddLockedPricingToOrganizations < ActiveRecord::Migration[7.2]
  def change
    add_column :organizations, :locked_price_monthly,     :decimal, precision: 10, scale: 2
    add_column :organizations, :locked_price_monthly_usd, :decimal, precision: 10, scale: 2

    # Poblar orgs existentes con el precio vigente de su plan actual
    # para que el cambio sea transparente para clientes actuales.
    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE organizations o
          SET
            locked_price_monthly     = pc.price_monthly,
            locked_price_monthly_usd = pc.price_monthly_usd
          FROM plan_configurations pc
          WHERE pc.plan = o.plan
            AND o.locked_price_monthly IS NULL
        SQL
      end
    end
  end
end
