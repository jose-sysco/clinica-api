module Api
  module Superadmin
    class OrganizationsController < BaseController
      def index
        ActsAsTenant.without_tenant do
          orgs = Organization.order(created_at: :desc)
          orgs = orgs.where(status: params[:status]) if params[:status].present?
          orgs = orgs.where(plan: params[:plan])     if params[:plan].present?

          if params[:q].present?
            q = "%#{params[:q].downcase}%"
            orgs = orgs.where("LOWER(name) LIKE ? OR LOWER(email) LIKE ? OR slug LIKE ?", q, q, q)
          end

          pagy, orgs = pagy(orgs, limit: 15)

          render json: {
            data:       orgs.map { |o| org_summary_json(o) },
            pagination: pagy_metadata(pagy)
          }
        end
      end

      def show
        ActsAsTenant.without_tenant do
          org = Organization.find(params[:id])
          render json: org_detail_json(org)
        end
      end

      def create
        ActsAsTenant.without_tenant do
          org = nil
          ActiveRecord::Base.transaction do
            org = Organization.new(org_create_params)
            org.save!

            admin_email = params.dig(:admin, :email).presence || org.email
            admin = User.new(
              first_name:            params.dig(:admin, :first_name),
              last_name:             params.dig(:admin, :last_name),
              email:                 admin_email,
              password:              params.dig(:admin, :password),
              password_confirmation: params.dig(:admin, :password),
              organization:          org,
              role:                  :admin,
              status:                :active,
              email_verified_at:     Time.current
            )
            admin.save!
          end
          render json: org_detail_json(org), status: :created
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def export_backup
        require "zip"
        require "csv"

        ActsAsTenant.without_tenant do
          org = Organization.find(params[:id])
          tz  = org.timezone

          zip_data = ActsAsTenant.with_tenant(org) do
            buffer = Zip::OutputStream.write_buffer do |zip|
              zip.put_next_entry("pacientes.csv")
              zip.write(patients_csv(tz))

              zip.put_next_entry("citas.csv")
              zip.write(appointments_csv(tz))

              zip.put_next_entry("expedientes.csv")
              zip.write(medical_records_csv(tz))
            end
            buffer.string
          end

          filename = "backup_#{org.slug}_#{Date.today.strftime('%Y%m%d')}.zip"
          send_data zip_data, filename: filename, type: "application/zip", disposition: "attachment"
        end
      end

      def impersonate
        ActsAsTenant.without_tenant do
          org   = Organization.find(params[:id])
          admin = org.users.find_by(role: :admin, status: :active)

          unless admin
            render json: { error: "No hay un administrador activo en esta organización" }, status: :unprocessable_entity
            return
          end

          jti     = SecureRandom.uuid
          payload = {
            sub: admin.id.to_s,
            jti: jti,
            exp: 1.hour.from_now.to_i,
            org: org.id
          }
          token = JWT.encode(payload, jwt_secret, "HS256")

          render json: {
            token:             token,
            organization_slug: org.slug,
            organization_name: org.name,
            organization_id:   org.id,
            user: {
              id:        admin.id,
              full_name: admin.full_name,
              email:     admin.email,
              role:      admin.role
            }
          }
        end
      end

      def update_license
        ActsAsTenant.without_tenant do
          org = Organization.find(params[:id])

          # Snapshot of fields before the update for the audit log
          tracked_fields = %i[plan status trial_ends_at suspended_at locked_price_monthly locked_price_monthly_usd max_doctors_override max_patients_override salesperson_id]
          before_snapshot = tracked_fields.index_with { |f| org.public_send(f).to_s }

          updates = {}
          updates[:plan]          = params[:plan]          if params[:plan].present?
          updates[:status]        = params[:status]        if params[:status].present?
          updates[:trial_ends_at] = params[:trial_ends_at] if params[:trial_ends_at].present?

          if params[:status] == "suspended"
            updates[:suspended_at] = Time.current
          elsif params[:status] == "active"
            updates[:suspended_at] = nil
          end

          # Precio personalizado explícito (descuento, acuerdo especial)
          if params[:locked_price_monthly].present?
            updates[:locked_price_monthly] = params[:locked_price_monthly]
          end
          if params[:locked_price_monthly_usd].present?
            updates[:locked_price_monthly_usd] = params[:locked_price_monthly_usd]
          end

          # Límites de capacidad personalizados (null = limpiar override, usa plan)
          if params.key?(:max_doctors_override)
            updates[:max_doctors_override] = params[:max_doctors_override].presence
          end
          if params.key?(:max_patients_override)
            updates[:max_patients_override] = params[:max_patients_override].presence
          end

          # Vendedor asignado
          if params.key?(:salesperson_id)
            updates[:salesperson_id] = params[:salesperson_id].presence
          end

          # Si cambia de plan y no se especificó precio personalizado,
          # actualizar locked_price al precio vigente del nuevo plan.
          if params[:plan].present? && params[:locked_price_monthly].blank?
            plan_config = PlanConfiguration.find_by(plan: params[:plan])
            if plan_config
              updates[:locked_price_monthly]     = plan_config.price_monthly
              updates[:locked_price_monthly_usd] = plan_config.price_monthly_usd
            end
          end

          org.update!(updates)

          # Build diff for audit log
          after_snapshot = tracked_fields.index_with { |f| org.public_send(f).to_s }
          diff = tracked_fields.each_with_object({}) do |field, h|
            next if before_snapshot[field] == after_snapshot[field]

            h[field] = { from: before_snapshot[field], to: after_snapshot[field] }
          end

          if diff.any? || params[:notes].present?
            LicenseChangeLog.create!(
              organization: org,
              changed_by:   current_user,
              change_data:  diff,
              notes:        params[:notes].presence
            )
          end

          render json: org_detail_json(org)
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def license_logs
        ActsAsTenant.without_tenant do
          org  = Organization.find(params[:id])
          logs = org.license_change_logs.order(created_at: :desc).limit(50)
          render json: logs.map { |l| license_log_json(l) }
        end
      end

      def billing_history
        ActsAsTenant.without_tenant do
          org     = Organization.find(params[:id])
          records = BillingRecord.where(organization: org).order(period: :desc)
          plan_configs = PlanConfiguration.all.index_by(&:plan)

          render json: records.map { |r|
            price_gtq = org.locked_price_monthly.presence&.to_f ||
                        plan_configs[org.plan]&.price_monthly.to_f
            billing_history_json(r, price_gtq)
          }
        end
      end

      private

      def patients_csv(tz)
        patients = Patient.includes(:owner).order(:name).all
        CSV.generate(encoding: "UTF-8") do |csv|
          csv << %w[id nombre tipo especie raza genero fecha_nacimiento propietario_nombre propietario_email propietario_telefono alergias condiciones_cronicas notas estado creado_en]
          patients.each do |p|
            csv << [
              p.id, p.name, p.patient_type, p.species, p.breed, p.gender,
              p.birthdate,
              p.owner&.full_name, p.owner&.email, p.owner&.phone,
              p.allergies, p.chronic_conditions, p.notes, p.status,
              p.created_at&.in_time_zone(tz)&.strftime("%Y-%m-%d %H:%M")
            ]
          end
        end
      end

      def appointments_csv(tz)
        appts = Appointment.includes(:patient, :location, doctor: :user).order(:scheduled_at).all
        CSV.generate(encoding: "UTF-8") do |csv|
          csv << %w[id paciente doctor sede estado tipo fecha_hora motivo notas creado_en]
          appts.each do |a|
            csv << [
              a.id,
              a.patient.name,
              a.doctor.full_name,
              a.location&.name,
              a.status,
              a.appointment_type,
              a.scheduled_at.in_time_zone(tz).strftime("%Y-%m-%d %H:%M"),
              a.reason,
              a.notes,
              a.created_at.in_time_zone(tz).strftime("%Y-%m-%d %H:%M")
            ]
          end
        end
      end

      def medical_records_csv(tz)
        records = MedicalRecord.includes(:patient, doctor: :user).order(:created_at).all
        CSV.generate(encoding: "UTF-8") do |csv|
          csv << %w[id paciente doctor diagnostico tratamiento medicamentos notas peso_kg temperatura proxima_visita creado_en]
          records.each do |r|
            csv << [
              r.id,
              r.patient.name,
              r.doctor.full_name,
              r.diagnosis,
              r.treatment,
              r.medications,
              r.notes,
              r.weight,
              r.temperature,
              r.next_visit_date,
              r.created_at.in_time_zone(tz).strftime("%Y-%m-%d %H:%M")
            ]
          end
        end
      end

      def jwt_secret
        ENV["DEVISE_JWT_SECRET_KEY"] || Rails.application.credentials.devise_jwt_secret_key
      end

      def org_create_params
        params.require(:organization).permit(
          :name, :email, :phone, :address, :city, :country, :timezone, :clinic_type
        )
      end

      def org_summary_json(org)
        plan_config = PlanConfiguration.find_by(plan: org.plan)

        {
          id:                        org.id,
          name:                      org.name,
          slug:                      org.slug,
          email:                     org.email,
          phone:                     org.phone,
          city:                      org.city,
          country:                   org.country,
          clinic_type:               org.clinic_type,
          status:                    org.status,
          plan:                      org.plan,
          trial_ends_at:             org.trial_ends_at,
          trial_days_remaining:      org.trial_days_remaining,
          trial_expired:             org.trial_expired?,
          on_trial:                  org.trial?,
          expiring_soon:             org.expiring_soon?,
          suspended_at:              org.suspended_at,
          users_count:               org.users.count,
          doctors_count:             org.doctors.count,
          patients_count:            org.patients.count,
          appointments_count:        org.appointments.count,
          last_appointment_at:       org.appointments.maximum(:created_at),
          created_at:                org.created_at,
          registration_ip:           org.registration_ip,
          locked_price_monthly:      org.locked_price_monthly,
          locked_price_monthly_usd:  org.locked_price_monthly_usd,
          plan_price_monthly:        plan_config&.price_monthly,
          plan_price_monthly_usd:    plan_config&.price_monthly_usd,
          has_custom_price:          org.locked_price_monthly.present? &&
                                       org.locked_price_monthly != plan_config&.price_monthly,
          max_doctors_override:      org.max_doctors_override,
          max_patients_override:     org.max_patients_override,
          effective_max_doctors:     org.effective_max_doctors,
          effective_max_patients:    org.effective_max_patients,
          salesperson_id:            org.salesperson_id,
          salesperson:               org.salesperson ? { id: org.salesperson.id, name: org.salesperson.name, commission_for_plan: org.salesperson.commission_for_plan(org.plan), commission_by_plan: org.salesperson.commission_by_plan } : nil
        }
      end

      def org_detail_json(org)
        org_summary_json(org).merge(
          phone:     org.phone,
          address:   org.address,
          city:      org.city,
          country:   org.country,
          timezone:  org.timezone,
          subdomain: org.subdomain,
          users:     org.users.order(:role, :first_name).map do |u|
            { id: u.id, full_name: u.full_name, email: u.email, role: u.role, status: u.status, last_login_ip: u.last_login_ip }
          end
        )
      end

      def license_log_json(log)
        {
          id:         log.id,
          changes:    log.change_data,
          notes:      log.notes,
          changed_by: log.changed_by&.full_name || "Sistema",
          created_at: log.created_at
        }
      end

      def billing_history_json(record, price_gtq)
        {
          id:          record.id,
          period:      record.period.strftime("%Y-%m"),
          period_label: record.period.strftime("%B %Y"),
          amount_paid: record.amount_paid,
          currency:    record.currency,
          notes:       record.notes,
          recorded_at: record.recorded_at,
          recorded_by: record.recorded_by&.full_name,
          expected:    price_gtq,
          difference:  (record.amount_paid.to_f - price_gtq).round(2)
        }
      end
    end
  end
end
