# == Schema Information
#
# Table name: appointments
#
#  id                  :bigint           not null, primary key
#  organization_id     :integer          not null
#  doctor_id           :integer          not null
#  patient_id          :integer          not null
#  owner_id            :integer          not null
#  scheduled_at        :datetime         not null
#  ends_at             :datetime         not null
#  status              :integer          default("pending"), not null
#  appointment_type    :integer          default("first_visit"), not null
#  reason              :text             not null
#  notes               :text
#  cancelled_by        :integer
#  cancellation_reason :text
#  confirmed_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
class Appointment < ApplicationRecord
  # Multitenant
  acts_as_tenant :organization

  # Asociaciones
  belongs_to :organization
  belongs_to :doctor
  belongs_to :patient
  belongs_to :owner

  has_one :medical_record

  # Enums
  enum :status, { pending: 0, confirmed: 1, in_progress: 2, completed: 3, cancelled: 4, no_show: 5 }
  enum :appointment_type, { first_visit: 0, follow_up: 1, emergency: 2, routine: 3 }
  enum :cancelled_by, { cancelled_by_patient: 0, cancelled_by_doctor: 1, cancelled_by_system: 2 }

  # Validaciones
  validates :scheduled_at,      presence: true
  validates :ends_at,           presence: true
  validates :status,            presence: true
  validates :appointment_type,  presence: true
  validates :reason,            presence: true
  validate  :ends_at_after_scheduled_at
  validate  :no_double_booking
  validate  :within_doctor_schedule
  validate  :doctor_not_blocked
  validate  :valid_status_transition

  # Callbacks
  before_validation :set_ends_at, if: -> { scheduled_at.present? && ends_at.blank? }
  before_save       :set_confirmed_at, if: -> { status_changed? && confirmed? }

  # Scopes
  scope :upcoming,   -> { where("scheduled_at >= ?", Time.current).order(:scheduled_at) }
  scope :past,       -> { where("scheduled_at < ?", Time.current).order(scheduled_at: :desc) }
  scope :today,      -> { where(scheduled_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :for_doctor, ->(doctor_id) { where(doctor_id: doctor_id) }
  scope :for_patient, ->(patient_id) { where(patient_id: patient_id) }
  scope :by_status,   ->(status) { where(status: status) }
  scope :by_type,     ->(type) { where(appointment_type: type) }
  scope :by_date,     ->(date) { where(scheduled_at: date.to_date.beginning_of_day..date.to_date.end_of_day) }
  scope :by_range,    ->(from, to) { where(scheduled_at: from.to_date.beginning_of_day..to.to_date.end_of_day) }

  # Disparar los jobs desde el modelo
  after_create_commit :schedule_confirmation
  after_update_commit :handle_status_change

  private

  def ends_at_after_scheduled_at
    return if scheduled_at.blank? || ends_at.blank?

    if ends_at <= scheduled_at
      errors.add(:ends_at, "debe ser posterior a la hora de inicio")
    end
  end

  def no_double_booking
    return if scheduled_at.blank? || ends_at.blank?

    overlapping = Appointment.where(doctor_id: doctor_id)
                             .where.not(id: id)
                             .where.not(status: [:cancelled, :no_show])
                             .where("scheduled_at < ? AND ends_at > ?", ends_at, scheduled_at)

    if overlapping.exists?
      errors.add(:base, "el doctor ya tiene una cita en ese horario")
    end
  end

  def within_doctor_schedule
    return if scheduled_at.blank?

    day = scheduled_at.wday
    time = scheduled_at.strftime("%H:%M")

    schedule = doctor.schedules.active.find_by(day_of_week: day)

    unless schedule && time >= schedule.start_time.strftime("%H:%M") && time < schedule.end_time.strftime("%H:%M")
      errors.add(:scheduled_at, "está fuera del horario del doctor")
    end
  end

  def doctor_not_blocked
    return if scheduled_at.blank? || ends_at.blank?

    blocked = doctor.schedule_blocks.for_range(scheduled_at, ends_at)

    if blocked.exists?
      errors.add(:base, "el doctor tiene un bloqueo en ese horario")
    end
  end

  def set_ends_at
    self.ends_at = scheduled_at + doctor.consultation_duration.minutes
  end

  def set_confirmed_at
    self.confirmed_at = Time.current
  end

  def schedule_confirmation
    AppointmentConfirmationJob.perform_later(id)
  end

  def handle_status_change
    return unless saved_change_to_status?

    case status
    when "confirmed"
      AppointmentConfirmationJob.perform_later(id)
    when "cancelled"
      AppointmentCancellationJob.perform_later(id)
      WaitlistNotificationJob.perform_later(id)
    end
  end

  def valid_status_transition
    return if new_record?
    return unless status_changed?

    allowed = {
      "pending" => ["confirmed", "cancelled"],
      "confirmed" => ["in_progress", "cancelled", "completed"],
      "in_progress" => ["completed", "no_show"],
      "completed" => [],
      "cancelled" => [],
      "no_show" => []
    }

    unless allowed[status_was]&.include?(status)
      errors.add(:status, "no puede cambiar de '#{status_was}' a '#{status}'")
    end
  end
end
