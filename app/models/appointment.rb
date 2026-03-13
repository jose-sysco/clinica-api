class Appointment < ApplicationRecord
  # Multitenant
  acts_as_tenant :organization

  # Asociaciones
  belongs_to :organization
  belongs_to :doctor
  belongs_to :patient
  belongs_to :owner

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

  # Callbacks
  before_validation :set_ends_at, if: -> { scheduled_at.present? && ends_at.blank? }
  before_save       :set_confirmed_at, if: -> { status_changed? && confirmed? }

  # Scopes
  scope :upcoming,   -> { where("scheduled_at >= ?", Time.current).order(:scheduled_at) }
  scope :past,       -> { where("scheduled_at < ?", Time.current).order(scheduled_at: :desc) }
  scope :today,      -> { where(scheduled_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :for_doctor, ->(doctor_id) { where(doctor_id: doctor_id) }
  scope :for_patient, ->(patient_id) { where(patient_id: patient_id) }

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
end