class Doctor < ApplicationRecord
  # Multitenant
  acts_as_tenant :organization

  # Asociaciones
  belongs_to :organization
  belongs_to :user
  has_many   :schedules,       dependent: :destroy
  has_many   :schedule_blocks, dependent: :destroy
  has_many   :appointments,    dependent: :destroy

  # Enums
  enum :status, { active: 0, inactive: 1, on_leave: 2 }

  # Validaciones
  validates :specialty,            presence: true
  validates :consultation_duration, presence: true, numericality: { greater_than: 0 }
  validates :license_number,        uniqueness: true, allow_blank: true

  # Scopes
  scope :active, -> { where(status: :active) }

  # Helpers
  def full_name
    user.full_name
  end

  def available_on?(day_of_week)
    schedules.active.exists?(day_of_week: day_of_week)
  end
end