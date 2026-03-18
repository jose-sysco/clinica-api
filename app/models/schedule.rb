# == Schema Information
#
# Table name: schedules
#
#  id              :bigint           not null, primary key
#  organization_id :integer          not null
#  doctor_id       :integer          not null
#  day_of_week     :integer          not null
#  start_time      :time             not null
#  end_time        :time             not null
#  is_active       :boolean          default(TRUE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class Schedule < ApplicationRecord
  # Multitenant
  acts_as_tenant :organization

  # Asociaciones
  belongs_to :organization
  belongs_to :doctor

  # Enums
  enum :day_of_week, { sunday: 0, monday: 1, tuesday: 2, wednesday: 3, thursday: 4, friday: 5, saturday: 6 }

  # Validaciones
  validates :day_of_week, presence: true
  validates :start_time,  presence: true
  validates :end_time,    presence: true
  validates :day_of_week, uniqueness: { scope: :doctor_id, message: "ya tiene un horario este día" }
  validate  :end_time_after_start_time

  # Scopes
  scope :active, -> { where(is_active: true) }

  private

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?

    if end_time <= start_time
      errors.add(:end_time, "debe ser posterior a la hora de inicio")
    end
  end
end
