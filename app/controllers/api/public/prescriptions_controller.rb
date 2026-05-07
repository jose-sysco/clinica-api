module Api
  module Public
    class PrescriptionsController < ActionController::API
      # GET /api/public/prescriptions/:token
      def show
        prescription = ActsAsTenant.without_tenant do
          Prescription.includes(:organization, :doctor, :patient)
                      .find_by!(verification_token: params[:token])
        end

        render json: public_prescription_json(prescription)
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Receta no encontrada" }, status: :not_found
      end

      private

      def public_prescription_json(p)
        {
          id:           p.id,
          status:       p.status,
          revoked:      p.revoked?,
          diagnosis:    p.diagnosis,
          medications:  p.medications,
          notes:        p.notes,
          issued_at:    p.issued_at,
          valid_until:  p.valid_until,
          doctor_name:  p.doctor.full_name,
          patient_name: p.patient.name,
          clinic_name:  p.organization.name,
          clinic_phone: p.organization.phone
        }
      end
    end
  end
end
