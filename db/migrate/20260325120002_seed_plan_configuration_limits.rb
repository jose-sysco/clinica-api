# Data migration: pobla display_name, límites y precios USD en plan_configurations.
# Mantiene los enum values existentes (trial=0, basic=1, professional=2, enterprise=3).
# El campo price_monthly existente (GTQ) no se toca.
class SeedPlanConfigurationLimits < ActiveRecord::Migration[7.2]
  PLAN_DATA = {
    0 => { display_name: "Free Trial",   max_doctors: 2,   max_patients: 50,   price_monthly_usd: 0.00 },
    1 => { display_name: "Starter",      max_doctors: 3,   max_patients: 200,  price_monthly_usd: 20.00 },
    2 => { display_name: "Pro",          max_doctors: 10,  max_patients: 1000, price_monthly_usd: 50.00 },
    3 => { display_name: "Enterprise",   max_doctors: nil, max_patients: nil,  price_monthly_usd: 400.00 },
  }.freeze

  # También fija price_monthly (GTQ) si aún está en 0
  PLAN_GTQ = { 0 => 0, 1 => 150.0, 2 => 400.0, 3 => 3000.0 }.freeze

  def up
    PLAN_DATA.each do |plan_int, attrs|
      config = PlanConfiguration.find_by(plan: plan_int)
      next unless config

      update_hash = attrs.dup
      update_hash[:price_monthly] = PLAN_GTQ[plan_int] if config.price_monthly.to_f.zero?
      config.update_columns(update_hash)
    end
  end

  def down
    PlanConfiguration.update_all(display_name: nil, max_doctors: nil, max_patients: nil, price_monthly_usd: 0)
  end
end
