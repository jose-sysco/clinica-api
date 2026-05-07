module Api
  module Public
    class AdmissionsController < BaseController
      # GET /api/public/admissions/:token
      def show
        form = AdmissionForm.find_by(token: params[:token])
        unless form
          render json: { error: "Formulario no encontrado" }, status: :not_found
          return
        end

        ActsAsTenant.with_tenant(form.organization) do
          appt = form.appointment
          render json: {
            submitted:    form.submitted?,
            patient_name: form.patient_name,
            clinic_name:  form.organization.name,
            doctor_name:  appt.doctor.full_name,
            scheduled_at: appt.scheduled_at.in_time_zone(form.organization.timezone)
                              .strftime("%-d de %B de %Y a las %H:%M"),
            form: form.submitted? ? admission_json(form) : nil
          }
        end
      end

      # PATCH /api/public/admissions/:token
      def update
        form = AdmissionForm.find_by(token: params[:token])
        unless form
          render json: { error: "Formulario no encontrado" }, status: :not_found
          return
        end

        if form.submitted?
          render json: { error: "Este formulario ya fue enviado." }, status: :unprocessable_entity
          return
        end

        ActsAsTenant.with_tenant(form.organization) do
          form.submit!(params.permit(:allergies, :current_medications, :medical_history,
                                     :notes, :patient_dob).to_h)
          render json: { message: "Formulario enviado correctamente. ¡Hasta pronto!" }
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.first }, status: :unprocessable_entity
      end

      private

      def admission_json(form)
        {
          allergies:            form.allergies,
          current_medications:  form.current_medications,
          medical_history:      form.medical_history,
          notes:                form.notes,
          patient_dob:          form.patient_dob,
          submitted_at:         form.submitted_at
        }
      end
    end
  end
end
