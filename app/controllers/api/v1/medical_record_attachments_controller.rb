module Api
  module V1
    class MedicalRecordAttachmentsController < ApplicationController
      before_action :set_record

      # GET /api/v1/medical_records/:medical_record_id/attachments
      def index
        authorize @record, policy_class: MedicalRecordPolicy
        render json: attachments_json(@record)
      end

      # POST /api/v1/medical_records/:medical_record_id/attachments
      def create
        authorize @record, policy_class: MedicalRecordPolicy

        files = Array(params[:files])
        if files.empty?
          return render json: { error: "No se recibieron archivos" }, status: :unprocessable_entity
        end

        total = @record.attachments.count + files.size
        if total > MedicalRecord::MAX_ATTACHMENTS
          return render json: { error: "Límite de #{MedicalRecord::MAX_ATTACHMENTS} archivos por expediente" }, status: :unprocessable_entity
        end

        files.each { |f| @record.attachments.attach(f) }

        if @record.valid?
          render json: attachments_json(@record), status: :created
        else
          render json: { error: @record.errors.full_messages.first }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/medical_records/:medical_record_id/attachments/:id
      def destroy
        authorize @record, policy_class: MedicalRecordPolicy

        blob = @record.attachments.find { |a| a.id.to_s == params[:id].to_s }
        return render json: { error: "Adjunto no encontrado" }, status: :not_found unless blob

        blob.purge_later
        head :no_content
      end

      private

      def set_record
        @record = MedicalRecord.find(params[:medical_record_id])
      end

      def attachments_json(record)
        record.attachments.map do |attachment|
          {
            id:           attachment.id,
            filename:     attachment.filename.to_s,
            content_type: attachment.content_type,
            byte_size:    attachment.byte_size,
            url:          rails_blob_url(attachment, disposition: "inline", host: request.base_url),
            created_at:   attachment.created_at
          }
        end
      end
    end
  end
end
