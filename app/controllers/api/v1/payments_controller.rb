module Api
  module V1
    class PaymentsController < BaseController
      before_action :set_appointment, only: [ :index, :create ]

      # GET /api/v1/appointments/:appointment_id/payments
      def index
        authorize Payment, policy_class: PaymentPolicy
        payments = @appointment.payments.includes(:recorded_by).order(created_at: :desc)
        render json: payments.map { |p| payment_json(p) }
      end

      # POST /api/v1/appointments/:appointment_id/payments
      def create
        authorize Payment, policy_class: PaymentPolicy
        payment = @appointment.payments.new(payment_params)
        payment.organization = ActsAsTenant.current_tenant
        payment.recorded_by  = current_user
        payment.save!

        render json: {
          payment:             payment_json(payment),
          payment_summary:     payment_summary(@appointment.reload)
        }, status: :created

      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      # GET /api/v1/payments  (reporte general)
      def index_all
        authorize Payment, policy_class: PaymentPolicy

        scope = Payment.includes(appointment: [ :doctor, :patient ])

        scope = scope.by_method(params[:payment_method])        if params[:payment_method].present?
        scope = scope.joins(:appointment)
                     .where(appointments: { doctor_id: params[:doctor_id] }) if params[:doctor_id].present?

        if params[:from].present? && params[:to].present?
          scope = scope.by_date_range(params[:from].to_date, params[:to].to_date)
        elsif params[:from].present?
          scope = scope.where("payments.created_at >= ?", params[:from].to_date.beginning_of_day)
        end

        totals = {
          cash:     scope.by_method(:cash).sum(:amount).to_f,
          card:     scope.by_method(:card).sum(:amount).to_f,
          transfer: scope.by_method(:transfer).sum(:amount).to_f,
          other:    scope.by_method(:other).sum(:amount).to_f,
          total:    scope.sum(:amount).to_f
        }

        scope = scope.order(Arel.sql("payments.created_at DESC"))
        pagy, payments = pagy(scope, limit: params[:per_page] || 20)

        render json: {
          data:       payments.map { |p| payment_json_full(p) },
          totals:     totals,
          pagination: pagy_metadata(pagy)
        }
      end

      private

      def set_appointment
        @appointment = Appointment.find(params[:appointment_id])
      end

      def payment_params
        params.require(:payment).permit(:amount, :payment_method, :notes)
      end

      def payment_json(payment)
        {
          id:             payment.id,
          amount:         payment.amount.to_f,
          payment_method: payment.payment_method,
          notes:          payment.notes,
          recorded_by:    payment.recorded_by.full_name,
          created_at:     payment.created_at
        }
      end

      def payment_json_full(payment)
        payment_json(payment).merge(
          appointment_id: payment.appointment_id,
          patient_name:   payment.appointment.patient.name,
          doctor_name:    payment.appointment.doctor.full_name,
          scheduled_at:   payment.appointment.scheduled_at
        )
      end

      def payment_summary(appointment)
        {
          total_paid:       appointment.total_paid,
          consultation_fee: appointment.doctor.consultation_fee&.to_f,
          payment_status:   appointment.payment_status
        }
      end
    end
  end
end
