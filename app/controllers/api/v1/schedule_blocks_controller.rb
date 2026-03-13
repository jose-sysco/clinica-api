module Api
  module V1
    class ScheduleBlocksController < BaseController
      before_action :set_doctor
      before_action :set_schedule_block, only: [:destroy]

      def index
        blocks = @doctor.schedule_blocks.upcoming.order(:start_datetime)
        render json: blocks.map { |b| block_json(b) }
      end

      def create
        block = @doctor.schedule_blocks.new(block_params)
        block.save!
        render json: block_json(block), status: :created
      end

      def destroy
        @block.destroy!
        render json: { message: "Bloqueo eliminado correctamente" }
      end

      private

      def set_doctor
        @doctor = Doctor.find(params[:doctor_id])
      end

      def set_schedule_block
        @block = @doctor.schedule_blocks.find(params[:id])
      end

      def block_params
        params.require(:schedule_block).permit(
          :start_datetime, :end_datetime, :reason
        )
      end

      def block_json(block)
        {
          id:             block.id,
          start_datetime: block.start_datetime,
          end_datetime:   block.end_datetime,
          reason:         block.reason
        }
      end
    end
  end
end