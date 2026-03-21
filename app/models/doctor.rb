# == Schema Information
#
# Table name: doctors
#
#  id                    :bigint           not null, primary key
#  organization_id       :integer          not null
#  user_id               :integer          not null
#  specialty             :string           not null
#  license_number        :string
#  bio                   :text
#  consultation_duration :integer          default(30), not null
#  status                :integer          default("active"), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
class Doctor < ApplicationRecord
  # Multitenant
  acts_as_tenant :organization

  # Asociaciones
  belongs_to :organization
  belongs_to :user
  has_many   :schedules,       dependent: :destroy
  has_many   :schedule_blocks, dependent: :destroy
  has_many   :appointments,    dependent: :destroy
  has_many :medical_records

  # Enums
  enum :status, { active: 0, inactive: 1, on_leave: 2 }

  # Validaciones
  validates :specialty,            presence: true
  validates :consultation_duration, presence: true, numericality: { greater_than: 0 }
  validates :license_number,        uniqueness: true, allow_blank: true
  validate  :within_doctor_limit,   on: :create

  # Scopes
  scope :active, -> { where(status: :active) }

  # Helpers
  def full_name
    user.full_name
  end

  private

  def within_doctor_limit
    return if organization.enabled_features.include?("multi_doctor")
    if organization.doctors.active.count >= 1
      errors.add(:base, "Tu plan solo permite 1 doctor activo. Actualiza tu suscripción para agregar más.")
    end
  end

  def available_on?(day_of_week)
    schedules.active.exists?(day_of_week: day_of_week)
  end
end
