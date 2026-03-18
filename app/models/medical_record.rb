# == Schema Information
#
# Table name: medical_records
#
#  id              :bigint           not null, primary key
#  organization_id :integer          not null
#  appointment_id  :integer          not null
#  patient_id      :integer          not null
#  doctor_id       :integer          not null
#  weight          :decimal(5, 2)
#  height          :decimal(5, 2)
#  temperature     :decimal(4, 1)
#  diagnosis       :text
#  treatment       :text
#  medications     :text
#  notes           :text
#  next_visit_date :date
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
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
