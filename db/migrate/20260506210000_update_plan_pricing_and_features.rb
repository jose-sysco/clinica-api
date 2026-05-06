# Actualiza precios, límites y features de los planes de suscripción.
# Los campos locked_price_monthly / locked_price_monthly_usd en organizations
# NO se tocan — los clientes existentes conservan su precio histórico.
class UpdatePlanPricingAndFeatures < ActiveRecord::Migration[7.2]
  UPDATES = {
    # basic → Starter: Q350, $47, 5 doctores, 500 pacientes
    1 => {
      price_monthly:     350.00,
      price_monthly_usd: 47.00,
      max_doctors:       5,
      max_patients:      500
    },
    # professional → Pro: Q700, $93, 10 doctores, 1000 pacientes + inventory
    2 => {
      price_monthly:     700.00,
      price_monthly_usd: 93.00,
      max_doctors:       10,
      max_patients:      1000
    },
    # enterprise: Q1800, $240, ilimitado (sin cambio en doctores/pacientes)
    3 => {
      price_monthly:     1800.00,
      price_monthly_usd: 240.00
    }
  }.freeze

  def up
    UPDATES.each do |plan_int, attrs|
      config = PlanConfiguration.find_by(plan: plan_int)
      next unless config

      config.update_columns(attrs)
    end

    # Agregar inventory a professional (Pro) si aún no lo tiene
    pro = PlanConfiguration.find_by(plan: 2)
    if pro && pro.features.is_a?(Array) && !pro.features.include?("inventory")
      pro.update_columns(features: pro.features + ["inventory"])
    end
  end

  def down
    rollback = {
      1 => { price_monthly: 450.00, price_monthly_usd: 60.00,  max_doctors: 3,  max_patients: 200 },
      2 => { price_monthly: 825.00, price_monthly_usd: 110.00, max_doctors: 10, max_patients: 1000 },
      3 => { price_monthly: 2625.00, price_monthly_usd: 350.00 }
    }

    rollback.each do |plan_int, attrs|
      config = PlanConfiguration.find_by(plan: plan_int)
      next unless config
      config.update_columns(attrs)
    end

    pro = PlanConfiguration.find_by(plan: 2)
    if pro && pro.features.is_a?(Array)
      pro.update_columns(features: pro.features.reject { |f| f == "inventory" })
    end
  end
end
