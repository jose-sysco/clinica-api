namespace :db do
  namespace :seed do
    # Corre datos esenciales de forma idempotente (seguro en producción).
    # No borra nada — usa find_or_create_by para evitar duplicados.
    # Uso: bin/rails db:seed:production
    desc "Seed datos esenciales de producción (idempotente)"
    task production: :environment do
      puts "=> Seeding plan_configurations..."

      plans = [
        {
          plan:              :trial,
          name:              "Trial",
          display_name:      "Free Trial",
          price_monthly:     0,
          price_monthly_usd: 0,
          max_doctors:       2,
          max_patients:      50,
          features:          %w[appointments medical_records notifications],
        },
        {
          plan:              :basic,
          name:              "Básico",
          display_name:      "Starter",
          price_monthly:     150.0,
          price_monthly_usd: 20.0,
          max_doctors:       3,
          max_patients:      200,
          features:          %w[appointments medical_records notifications reports],
        },
        {
          plan:              :professional,
          name:              "Profesional",
          display_name:      "Pro",
          price_monthly:     400.0,
          price_monthly_usd: 50.0,
          max_doctors:       10,
          max_patients:      1000,
          features:          %w[appointments medical_records notifications reports whatsapp_notifications multi_doctor],
        },
        {
          plan:              :enterprise,
          name:              "Empresarial",
          display_name:      "Enterprise",
          price_monthly:     3000.0,
          price_monthly_usd: 400.0,
          max_doctors:       nil,
          max_patients:      nil,
          features:          PlanConfiguration::FEATURES.keys,
        },
      ]

      ActsAsTenant.without_tenant do
        plans.each do |attrs|
          config = PlanConfiguration.find_or_initialize_by(plan: attrs[:plan])
          config.assign_attributes(attrs.except(:plan))
          if config.new_record?
            config.save!
            puts "   creado: #{attrs[:display_name]}"
          else
            config.save!
            puts "   actualizado: #{attrs[:display_name]}"
          end
        end
      end

      puts "=> plan_configurations OK (#{PlanConfiguration.count} planes)"
    end
  end
end
