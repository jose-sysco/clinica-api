module Api
  module V1
    class WaitlistEntriesController < BaseController

      def index
        entries = WaitlistEntry.includes(:patient, :doctor, :owner)

        entries = entries.for_doctor(params[:doctor_id]) if params[:doctor_id].present?
        entries = entries.for_patient(params[:patient_id]) if params[:patient_id].present?

        if params[:status].present?
          entries = entries.where(status: params[:status])
        else
          entries = entries.active
        end

        entries = entries.order(:created_at)

        render json: entries.map { |e| serialize(e) }
      end

      def create
        entry = WaitlistEntry.new(entry_params)
        entry.organization = current_organization

        if entry.save
          render json: serialize(entry), status: :created
        else
          render json: { errors: entry.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        entry = WaitlistEntry.find(params[:id])
        if entry.update(update_params)
          render json: serialize(entry)
        else
          render json: { errors: entry.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        entry = WaitlistEntry.find(params[:id])
        entry.destroy
        head :no_content
      end

      private

      def entry_params
        params.require(:waitlist_entry).permit(:doctor_id, :patient_id, :owner_id, :preferred_date, :notes)
      end

      def update_params
        params.require(:waitlist_entry).permit(:status, :notes)
      end

      def serialize(entry)
        {
          id:             entry.id,
          status:         entry.status,
          preferred_date: entry.preferred_date,
          notes:          entry.notes,
          notified_at:    entry.notified_at,
          created_at:     entry.created_at,
          position:       entry.status == "waiting" ? entry.position : nil,
          doctor: {
            id:         entry.doctor_id,
            full_name:  entry.doctor.full_name,
            specialty:  entry.doctor.specialty,
          },
          patient: {
            id:   entry.patient_id,
            name: entry.patient.name,
          },
          owner: {
            id:   entry.owner_id,
            name: entry.owner.full_name,
          },
        }
      end
    end
  end
end
