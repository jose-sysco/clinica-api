module Api
  module V1
    class PrescriptionsController < BaseController
      before_action :require_prescriptions_feature!
      before_action :set_prescription, only: [ :show, :update, :revoke, :download ]

      # GET /api/v1/prescriptions?patient_id=&medical_record_id=
      def index
        authorize Prescription, policy_class: PrescriptionPolicy
        scope = Prescription.includes(:doctor, :patient).recent
        scope = scope.where(patient_id: params[:patient_id])             if params[:patient_id].present?
        scope = scope.where(medical_record_id: params[:medical_record_id]) if params[:medical_record_id].present?
        render json: scope.map { |p| prescription_json(p) }
      end

      # GET /api/v1/prescriptions/:id
      def show
        authorize @prescription, policy_class: PrescriptionPolicy
        render json: prescription_json(@prescription)
      end

      # POST /api/v1/prescriptions
      def create
        authorize Prescription, policy_class: PrescriptionPolicy
        prescription = Prescription.new(prescription_params)
        prescription.organization = ActsAsTenant.current_tenant

        # Assign doctor — admin can specify, doctor always creates as themselves
        if current_user.doctor?
          prescription.doctor = current_user.doctor
        elsif params[:prescription][:doctor_id].present?
          prescription.doctor = Doctor.find(params[:prescription][:doctor_id])
        end

        prescription.save!
        render json: prescription_json(prescription), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      # PATCH /api/v1/prescriptions/:id
      def update
        authorize @prescription, policy_class: PrescriptionPolicy
        @prescription.update!(prescription_params)
        render json: prescription_json(@prescription)
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      # PATCH /api/v1/prescriptions/:id/revoke
      def revoke
        authorize @prescription, policy_class: PrescriptionPolicy
        @prescription.revoked!
        render json: { message: "Receta revocada", id: @prescription.id }
      end

      # GET /api/v1/prescriptions/:id/download
      def download
        authorize @prescription, policy_class: PrescriptionPolicy
        host = "#{request.protocol}#{request.host_with_port}"
        pdf_data = PrescriptionPdfService.new(@prescription, host).generate
        send_data pdf_data,
                  filename:    "receta_#{@prescription.verification_token.first(8)}.pdf",
                  type:        "application/pdf",
                  disposition: "inline"
      end

      private

      def set_prescription
        @prescription = Prescription.find(params[:id])
      end

      def prescription_params
        params.require(:prescription).permit(
          :patient_id,
          :appointment_id,
          :medical_record_id,
          :diagnosis,
          :notes,
          :issued_at,
          :valid_until,
          medications: [ :name, :dose, :frequency, :duration, :instructions ]
        )
      end

      def prescription_json(p)
        {
          id:                 p.id,
          verification_token: p.verification_token,
          status:             p.status,
          diagnosis:          p.diagnosis,
          notes:              p.notes,
          issued_at:          p.issued_at,
          valid_until:        p.valid_until,
          medications:        p.medications,
          doctor: {
            id:        p.doctor.id,
            full_name: p.doctor.full_name
          },
          patient: {
            id:   p.patient.id,
            name: p.patient.name
          },
          medical_record_id: p.medical_record_id,
          appointment_id:    p.appointment_id,
          public_url:        p.public_url("#{request.protocol}#{request.host_with_port}"),
          created_at:        p.created_at
        }
      end

      def require_prescriptions_feature!
        unless ActsAsTenant.current_tenant.enabled_features.include?("prescriptions")
          render json: { error: "Las recetas electrónicas no están disponibles en tu plan actual.", code: "feature_not_available" },
                 status: :payment_required
        end
      end
    end
  end
end
