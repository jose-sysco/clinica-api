module Api
  module V1
    class WeightRecordsController < BaseController
      before_action :set_patient

      def index
        records = @patient.weight_records.chronological
        render json: records.map { |r| weight_record_json(r) }
      end

      def create
        record = @patient.weight_records.new(weight_record_params)
        record.save!
        render json: weight_record_json(record), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def destroy
        record = @patient.weight_records.find(params[:id])
        record.destroy!
        render json: { message: "Registro eliminado" }
      end

      private

      def set_patient
        @patient = Patient.find(params[:patient_id])
      end

      def weight_record_params
        params.require(:weight_record).permit(:weight, :recorded_on, :notes)
      end

      def weight_record_json(record)
        {
          id:          record.id,
          weight:      record.weight,
          recorded_on: record.recorded_on,
          notes:       record.notes,
          created_at:  record.created_at
        }
      end
    end
  end
end
