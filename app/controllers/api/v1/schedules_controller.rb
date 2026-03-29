module Api
  module V1
    class SchedulesController < BaseController
      before_action :set_doctor
      before_action :set_schedule, only: [ :update, :destroy ]

      def index
        render json: @doctor.schedules.map { |s| schedule_json(s) }
      end

      def create
        schedule = @doctor.schedules.new(schedule_params)
        schedule.save!
        render json: schedule_json(schedule), status: :created
      end

      def update
        @schedule.update!(schedule_params)
        render json: schedule_json(@schedule)
      end

      def destroy
        @schedule.destroy!
        render json: { message: "Horario eliminado correctamente" }
      end

      private

      def set_doctor
        @doctor = Doctor.find(params[:doctor_id])
      end

      def set_schedule
        @schedule = @doctor.schedules.find(params[:id])
      end

      def schedule_params
        params.require(:schedule).permit(
          :day_of_week, :start_time, :end_time, :is_active
        )
      end

      def schedule_json(schedule)
        {
          id:          schedule.id,
          day_of_week: schedule.day_of_week,
          start_time:  schedule.start_time.strftime("%H:%M"),
          end_time:    schedule.end_time.strftime("%H:%M"),
          is_active:   schedule.is_active
        }
      end
    end
  end
end
