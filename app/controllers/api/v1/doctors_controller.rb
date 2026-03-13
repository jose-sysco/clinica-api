module Api
  module V1
    class DoctorsController < BaseController
      before_action :set_doctor, only: [:show, :update, :destroy]

      def index
        doctors = Doctor.active.includes(:user, :schedules)
        render json: doctors.map { |d| doctor_json(d) }
      end

      def show
        render json: doctor_json(@doctor)
      end

      def create
        doctor = Doctor.new(doctor_params)
        doctor.save!
        render json: doctor_json(doctor), status: :created
      end

      def update
        @doctor.update!(doctor_params)
        render json: doctor_json(@doctor)
      end

      def destroy
        @doctor.update!(status: :inactive)
        render json: { message: "Doctor desactivado correctamente" }
      end

      private

      def set_doctor
        @doctor = Doctor.find(params[:id])
      end

      def doctor_params
        params.require(:doctor).permit(
          :user_id, :specialty, :license_number,
          :bio, :consultation_duration, :status
        )
      end

      def doctor_json(doctor)
        {
          id:                   doctor.id,
          full_name:            doctor.full_name,
          specialty:            doctor.specialty,
          license_number:       doctor.license_number,
          bio:                  doctor.bio,
          consultation_duration: doctor.consultation_duration,
          status:               doctor.status,
          schedules:            doctor.schedules.map { |s| schedule_json(s) }
        }
      end

      def schedule_json(schedule)
        {
          id:          schedule.id,
          day_of_week: schedule.day_of_week,
          start_time:  schedule.start_time,
          end_time:    schedule.end_time,
          is_active:   schedule.is_active
        }
      end
    end
  end
end