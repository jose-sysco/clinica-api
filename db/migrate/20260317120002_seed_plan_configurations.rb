class SeedPlanConfigurations < ActiveRecord::Migration[7.2]
  DEFAULTS = [
    {
      plan: 0, name: "Trial", price_monthly: 0,
      features: '["appointments","medical_records","notifications"]'
    },
    {
      plan: 1, name: "Básico", price_monthly: 29.99,
      features: '["appointments","medical_records","notifications","reports"]'
    },
    {
      plan: 2, name: "Profesional", price_monthly: 59.99,
      features: '["appointments","medical_records","notifications","reports","whatsapp_notifications","multi_doctor"]'
    },
    {
      plan: 3, name: "Empresarial", price_monthly: 99.99,
      features: '["appointments","medical_records","notifications","reports","whatsapp_notifications","multi_doctor","inventory","custom_branding"]'
    }
  ].freeze

  def up
    DEFAULTS.each do |row|
      execute <<~SQL
        INSERT INTO plan_configurations (plan, name, price_monthly, features, created_at, updated_at)
        VALUES (#{row[:plan]}, '#{row[:name]}', #{row[:price_monthly]}, '#{row[:features]}', NOW(), NOW())
        ON CONFLICT DO NOTHING
      SQL
    end
  end

  def down
    execute "DELETE FROM plan_configurations"
  end
end
