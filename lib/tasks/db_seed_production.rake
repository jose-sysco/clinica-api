namespace :db do
  namespace :seed do
    # Corre datos esenciales de forma idempotente (seguro en producción).
    # No borra nada — usa find_or_initialize_by para evitar duplicados.
    # Uso: bin/rails db:seed:production
    #
    # Variables de entorno para el superadmin:
    #   SUPERADMIN_EMAIL    (default: superadmin@clinicaportal.com)
    #   SUPERADMIN_PASSWORD (requerido en producción)
    desc "Seed datos esenciales de producción (idempotente)"
    task production: :environment do

      # ── 1. plan_configurations ───────────────────────────────────────────────
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
          config.save!
          puts "   #{config.previously_new_record? ? 'creado' : 'actualizado'}: #{attrs[:display_name]}"
        end
      end

      puts "=> plan_configurations OK (#{PlanConfiguration.count} planes)"

      # ── 2. Organización sistema + usuario superadmin ─────────────────────────
      puts "=> Seeding superadmin..."

      superadmin_email    = ENV.fetch("SUPERADMIN_EMAIL",    "superadmin@clinicaportal.com")
      superadmin_password = ENV.fetch("SUPERADMIN_PASSWORD", nil)

      if superadmin_password.blank?
        puts "   ADVERTENCIA: SUPERADMIN_PASSWORD no definido — superadmin omitido."
        puts "   Agrega la env var y redeploy para crear el superadmin."
      else
        ActsAsTenant.without_tenant do
          # Organización contenedora del superadmin (no es una clínica real)
          sys_org = Organization.find_or_initialize_by(slug: "sistema-superadmin")
          if sys_org.new_record?
            sys_org.assign_attributes(
              name:        "Sistema",
              subdomain:   "sistema-superadmin",
              email:       superadmin_email,
              country:     "Guatemala",
              timezone:    "America/Guatemala",
              clinic_type: :general,
              status:      :active,
              plan:        :enterprise
            )
            sys_org.save!
            puts "   organización sistema creada"
          end

          # Usuario superadmin
          superadmin = User.find_or_initialize_by(email: superadmin_email)
          if superadmin.new_record?
            superadmin.assign_attributes(
              organization:          sys_org,
              first_name:            "Super",
              last_name:             "Admin",
              role:                  :superadmin,
              status:                :active,
              password:              superadmin_password,
              password_confirmation: superadmin_password
            )
            superadmin.save!
            puts "   superadmin creado: #{superadmin_email}"
          else
            puts "   superadmin ya existe: #{superadmin_email}"
          end
        end
      end

      puts ""
      puts "✅ Seed de producción completado."
    end
  end
end
