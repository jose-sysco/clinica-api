module Api
  module V1
    class AppointmentsController < BaseController
      before_action :set_appointment, only: [ :show, :update, :cancel, :confirm, :complete, :cancel_series, :no_show, :start ]

      def index
        authorize Appointment, policy_class: AppointmentPolicy

        appointments = Appointment.includes(:doctor, :patient, :owner)

        appointments = appointments.for_doctor(params[:doctor_id])      if params[:doctor_id].present?
        appointments = appointments.for_patient(params[:patient_id])    if params[:patient_id].present?
        appointments = appointments.today                               if params[:today] == "true"
        appointments = appointments.upcoming                            if params[:upcoming] == "true"
        appointments = appointments.past                               if params[:past] == "true"
        appointments = appointments.by_status(params[:status])          if params[:status].present?
        appointments = appointments.by_type(params[:appointment_type])  if params[:appointment_type].present?
        appointments = appointments.by_date(params[:date])              if params[:date].present?

        appointments = appointments.reorder(scheduled_at: :desc)

        if params[:from].present? && params[:to].present?
          appointments = appointments.by_range(params[:from], params[:to])
        end

        pagy, appointments = pagy(appointments, limit: params[:per_page] || 10)

        render json: {
          data:       appointments.map { |a| appointment_json(a) },
          pagination: pagy_metadata(pagy)
        }
      end

      def show
        authorize @appointment, policy_class: AppointmentPolicy
        render json: appointment_json(@appointment)
      end

      def create
        authorize Appointment, policy_class: AppointmentPolicy

        recurrence_type     = params[:recurrence_type].presence     # weekly | biweekly | monthly
        recurrence_sessions = params[:recurrence_sessions].to_i

        if recurrence_type.present? && recurrence_sessions > 1
          create_recurring_series(recurrence_type, recurrence_sessions)
        else
          create_single
        end
      end

      def update
        authorize @appointment, policy_class: AppointmentPolicy
        @appointment.update!(appointment_params)
        render json: appointment_json(@appointment)
      end

      def confirm
        authorize @appointment, policy_class: AppointmentPolicy

        if @appointment.confirmed?
          render json: { error: "La cita ya está confirmada" }, status: :unprocessable_entity
          return
        end

        @appointment.confirmed!
        # El modelo (handle_status_change) ya dispara AppointmentConfirmationJob
        # y programa AppointmentReminderJob — no duplicar aquí.
        render json: { message: "Cita confirmada correctamente" }, status: :ok
      end

      def cancel
        authorize @appointment, policy_class: AppointmentPolicy

        if @appointment.cancelled?
          render json: { error: "La cita ya está cancelada" }, status: :unprocessable_entity
          return
        end

        @appointment.update!(
          status:              :cancelled,
          cancelled_by:        params[:cancelled_by],
          cancellation_reason: params[:cancellation_reason]
        )
        render json: { message: "Cita cancelada correctamente" }
      end

      def cancel_series
        authorize @appointment, policy_class: AppointmentPolicy

        group_id = @appointment.recurrence_group_id
        unless group_id
          render json: { error: "Esta cita no pertenece a una serie" }, status: :unprocessable_entity
          return
        end

        cancelled_count = 0
        Appointment.where(recurrence_group_id: group_id)
                   .where.not(status: [ :cancelled, :completed ])
                   .find_each do |appt|
          appt.update!(
            status:              :cancelled,
            cancelled_by:        :cancelled_by_doctor,
            cancellation_reason: params[:cancellation_reason] || "Serie cancelada"
          )
          cancelled_count += 1
        end

        render json: { message: "#{cancelled_count} citas de la serie canceladas correctamente", cancelled: cancelled_count }
      end

      def complete
        authorize @appointment, policy_class: AppointmentPolicy

        if @appointment.completed?
          render json: { error: "La cita ya está completada" }, status: :unprocessable_entity
          return
        end

        @appointment.completed!
        render json: { message: "Cita completada correctamente" }, status: :ok
      end

      def start
        authorize @appointment, policy_class: AppointmentPolicy

        unless @appointment.confirmed?
          render json: { error: "Solo se pueden iniciar citas confirmadas" }, status: :unprocessable_entity
          return
        end

        @appointment.in_progress!
        render json: { message: "Cita en curso" }, status: :ok
      end

      def no_show
        authorize @appointment, policy_class: AppointmentPolicy

        if @appointment.no_show?
          render json: { error: "La cita ya está registrada como no presentada" }, status: :unprocessable_entity
          return
        end

        unless [ "pending", "confirmed", "in_progress" ].include?(@appointment.status)
          render json: { error: "No se puede registrar como no presentada desde el estado actual" }, status: :unprocessable_entity
          return
        end

        @appointment.no_show!
        render json: { message: "Registrada como no presentada" }, status: :ok
      end

      private

      # ── Single appointment ─────────────────────────────────────────────────

      def create_single
        appointment = Appointment.new(appointment_params)
        appointment.save!
        schedule_reminder(appointment)
        render json: appointment_json(appointment), status: :created
      end

      # ── Recurring series ───────────────────────────────────────────────────

      def create_recurring_series(recurrence_type, sessions)
        interval_days = case recurrence_type
        when "weekly"    then 7
        when "biweekly"  then 14
        when "monthly"   then nil   # use months logic
        end

        group_id   = SecureRandom.uuid
        base_attrs = appointment_params.to_h
        base_time  = Time.zone.parse(base_attrs["scheduled_at"])

        created = []

        Appointment.transaction do
          sessions.times do |i|
            scheduled_at = if recurrence_type == "monthly"
              base_time + i.months
            else
              base_time + (i * interval_days).days
            end

            appt = Appointment.new(
              base_attrs.merge(
                "scheduled_at"        => scheduled_at,
                "ends_at"             => nil,
                "recurrence_group_id" => group_id,
                "recurrence_index"    => i + 1,
                "recurrence_total"    => sessions
              )
            )
            appt.save!
            created << appt
          end
        end

        created.each { |a| schedule_reminder(a) }

        render json: {
          series_id:    group_id,
          total:        created.size,
          appointments: created.map { |a| appointment_json(a) }
        }, status: :created

      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: [ e.message ] }, status: :unprocessable_entity
      end

      # ── Helpers ────────────────────────────────────────────────────────────

      def schedule_reminder(appointment)
        reminder_time = appointment.scheduled_at - 24.hours
        if reminder_time > Time.current
          AppointmentReminderJob.set(wait_until: reminder_time).perform_later(appointment.id)
        end
      end

      def set_appointment
        @appointment = Appointment.find(params[:id])
      end

      def appointment_params
        params.require(:appointment).permit(
          :doctor_id, :patient_id, :owner_id,
          :scheduled_at, :ends_at, :appointment_type,
          :reason, :notes
        )
      end

      def appointment_json(appointment)
        {
          id:               appointment.id,
          scheduled_at:     appointment.scheduled_at.in_time_zone(appointment.organization.timezone).strftime("%Y-%m-%dT%H:%M:%S"),
          ends_at:          appointment.ends_at.in_time_zone(appointment.organization.timezone).strftime("%Y-%m-%dT%H:%M:%S"),
          status:           appointment.status,
          appointment_type: appointment.appointment_type,
          reason:           appointment.reason,
          notes:            appointment.notes,
          confirmed_at:     appointment.confirmed_at,
          recurrence_group_id: appointment.recurrence_group_id,
          recurrence_index:    appointment.recurrence_index,
          recurrence_total:    appointment.recurrence_total,
          doctor: {
            id:                 appointment.doctor.id,
            full_name:          appointment.doctor.full_name,
            inventory_movements: appointment.doctor.inventory_movements
          },
          patient: {
            id:   appointment.patient.id,
            name: appointment.patient.name
          },
          owner: {
            id:        appointment.owner.id,
            full_name: appointment.owner.full_name,
            phone:     appointment.owner.phone
          }
        }
      end
    end
  end
end
