class MedicalRecord < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :appointment
  belongs_to :patient
  belongs_to :doctor

  validates :appointment_id, uniqueness: true
  validates :diagnosis,      presence: true

  validates :weight,      numericality: { greater_than: 0 }, allow_blank: true
  validates :height,      numericality: { greater_than: 0 }, allow_blank: true
  validates :temperature, numericality: { greater_than: 0 }, allow_blank: true
end