module Api
  module Public
    class ClinicsController < BaseController
      CLINIC_TYPE_LABELS = {
        "veterinary"     => "Veterinaria",
        "pediatric"      => "Pediatría",
        "general"        => "Medicina General",
        "dental"         => "Odontología",
        "psychology"     => "Psicología",
        "physiotherapy"  => "Fisioterapia",
        "nutrition"      => "Nutrición",
        "beauty"         => "Estética",
        "coaching"       => "Coaching",
        "legal"          => "Legal",
        "fitness"        => "Fitness",
      }.freeze

      # GET /api/public/clinics
      def index
        ActsAsTenant.without_tenant do
          orgs = Organization
            .where(status: :active, listed: true)
            .where.not(plan: :trial)
            .where.not(slug: "sistema-superadmin")
            .order(:name)

          if params[:q].present?
            q = "%#{params[:q].downcase}%"
            orgs = orgs.where("LOWER(name) LIKE ? OR LOWER(city) LIKE ?", q, q)
          end

          orgs = orgs.where(clinic_type: params[:type]) if params[:type].present?

          render json: orgs.map { |o| clinic_summary_json(o) }
        end
      end

      # GET /api/public/clinics/:slug
      def show
        org = bookable_org!(params[:slug])
        return unless org

        ActsAsTenant.with_tenant(org) do
          Time.zone = org.timezone
          doctors   = Doctor.where(status: :active).order(:id)
          render json: clinic_detail_json(org, doctors)
        end
      end

      # GET /api/public/clinics/:slug/slots?doctor_id=&date=
      def slots
        org = bookable_org!(params[:slug])
        return unless org

        date_str = params[:date]
        if date_str.blank?
          render json: { error: "El parámetro date es requerido (YYYY-MM-DD)" }, status: :bad_request
          return
        end

        begin
          date = Date.parse(date_str)
        rescue ArgumentError
          render json: { error: "Formato de fecha inválido" }, status: :bad_request
          return
        end

        if date < Date.current
          render json: { error: "No puedes consultar fechas pasadas" }, status: :bad_request
          return
        end

        ActsAsTenant.with_tenant(org) do
          Time.zone = org.timezone
          doctor    = Doctor.find_by(id: params[:doctor_id], status: :active)

          unless doctor
            render json: { error: "Doctor no encontrado" }, status: :not_found
            return
          end

          slots = DoctorAvailabilityService.new(doctor, date, location_id: params[:location_id].presence).call

          render json: {
            date:   date_str,
            slots:  slots.map { |s|
              {
                starts_at: s[:starts_at].in_time_zone(org.timezone).strftime("%H:%M"),
                ends_at:   s[:ends_at].in_time_zone(org.timezone).strftime("%H:%M"),
              }
            }
          }
        end
      end

      # POST /api/public/clinics/:slug/book
      def book
        org = bookable_org!(params[:slug])
        return unless org

        # Validar campos requeridos
        required = %w[first_name last_name phone date time doctor_id reason]
        missing  = required.reject { |f| params[f].present? }
        if missing.any?
          render json: { error: "Faltan campos: #{missing.join(', ')}" }, status: :unprocessable_entity
          return
        end

        ActsAsTenant.with_tenant(org) do
          Time.zone = org.timezone

          doctor = Doctor.find_by(id: params[:doctor_id], status: :active)
          unless doctor
            render json: { error: "Doctor no encontrado" }, status: :not_found
            return
          end

          # Parsear fecha y hora
          begin
            scheduled_at = Time.zone.parse("#{params[:date]} #{params[:time]}")
          rescue ArgumentError
            render json: { error: "Fecha u hora inválida" }, status: :unprocessable_entity
            return
          end

          if scheduled_at <= Time.current
            render json: { error: "El horario seleccionado ya no está disponible" }, status: :unprocessable_entity
            return
          end

          ends_at = scheduled_at + doctor.consultation_duration.minutes

          # Buscar o crear Owner (contacto) — dedup por teléfono o email
          owner = Owner.find_by(phone: params[:phone])
          owner ||= Owner.find_by(email: params[:email]) if params[:email].present?

          unless owner
            owner = Owner.create!(
              first_name: params[:first_name],
              last_name:  params[:last_name],
              phone:      params[:phone],
              email:      params[:email].presence
            )
          end

          owner.update!(email: params[:email]) if params[:email].present? && owner.email.blank?

          # Determinar nombre y tipo de paciente
          p_type = org.clinic_type == "veterinary" ? :animal : :human
          p_name = params[:patient_name].presence ||
                   "#{params[:first_name]} #{params[:last_name]}".strip

          # Buscar o crear Patient
          patient = if params[:patient_name].present?
            owner.patients.find_by(name: p_name) ||
              Patient.create!(name: p_name, patient_type: p_type, owner: owner)
          else
            owner.patients.first ||
              Patient.create!(name: p_name, patient_type: p_type, owner: owner)
          end

          # Bloquear si el org trial llegó al límite
          if org.trial? && org.trial_appointments_limit_reached?
            render json: { error: "Esta clínica no está aceptando nuevas solicitudes en este momento." }, status: :unprocessable_entity
            return
          end

          # Crear cita y formulario de admisión en una transacción atómica
          appointment = nil
          admission   = nil

          ActiveRecord::Base.transaction do
            location = params[:location_id].present? ? Location.find_by(id: params[:location_id]) : nil
            appointment = Appointment.create!(
              doctor:       doctor,
              patient:      patient,
              owner:        owner,
              location:     location,
              scheduled_at: scheduled_at,
              ends_at:      ends_at,
              reason:       params[:reason]
            )

            admission = AdmissionForm.create!(
              appointment:  appointment,
              patient_name: p_name
            )
          end

          owner_name   = "#{params[:first_name]} #{params[:last_name]}".strip
          admission_url = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/reservas/admision/#{admission.token}"

          # Notificar a la clínica (admins y recepcionistas)
          admin_emails = org.users
                            .where(role: [ :admin, :receptionist ], status: :active)
                            .pluck(:email)
                            .compact

          BookingMailer.new_request(appointment, admin_emails, owner_name, params[:phone]).deliver_later if admin_emails.any?

          # Notificar al paciente si dejó email
          if params[:email].present?
            BookingMailer.request_received(appointment, params[:email], owner_name, admission_url).deliver_later
          end

          render json: {
            message:        "Solicitud recibida. La clínica confirmará tu cita pronto.",
            admission_token: admission.token,
            appointment:    {
              id:           appointment.id,
              scheduled_at: appointment.scheduled_at.in_time_zone(org.timezone).strftime("%-d de %B de %Y a las %H:%M"),
              doctor:       doctor.full_name,
              clinic:       org.name,
              status:       "pending"
            }
          }, status: :created
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.first }, status: :unprocessable_entity
      end

      private

      def clinic_summary_json(org)
        {
          id:           org.id,
          name:         org.name,
          slug:         org.slug,
          city:         org.city,
          country:      org.country,
          phone:        org.phone,
          clinic_type:  org.clinic_type,
          type_label:   CLINIC_TYPE_LABELS[org.clinic_type] || org.clinic_type,
          doctors_count: ActsAsTenant.with_tenant(org) { Doctor.where(status: :active).count },
          logo_url:     org.logo.presence,
        }
      end

      def clinic_detail_json(org, doctors)
        locations = ActsAsTenant.with_tenant(org) { Location.active.order(:name) }
        clinic_summary_json(org).merge(
          address:   org.address,
          email:     org.email,
          locations: locations.map { |l| { id: l.id, name: l.name, address: l.address, city: l.city } },
          doctors:   doctors.map { |d|
            {
              id:                    d.id,
              full_name:             d.full_name,
              specialty:             d.specialty,
              bio:                   d.bio,
              consultation_duration: d.consultation_duration,
              location_ids:          d.location_ids
            }
          }
        )
      end
    end
  end
end
