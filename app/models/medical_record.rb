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
  validate  :requires_assessment

  validates :weight,                   numericality: { greater_than: 0 },                             allow_blank: true
  validates :height,                   numericality: { greater_than: 0 },                             allow_blank: true
  validates :temperature,              numericality: { greater_than: 0 },                             allow_blank: true
  validates :heart_rate,               numericality: { only_integer: true, greater_than: 0 },         allow_blank: true
  validates :respiratory_rate,         numericality: { only_integer: true, greater_than: 0 },         allow_blank: true
  validates :blood_pressure_systolic,  numericality: { only_integer: true, greater_than: 0 },         allow_blank: true
  validates :blood_pressure_diastolic, numericality: { only_integer: true, greater_than: 0 },         allow_blank: true
  validates :oxygen_saturation,        numericality: { greater_than: 0, less_than_or_equal_to: 100 }, allow_blank: true

  private

  def requires_assessment
    if soap_assessment.blank? && diagnosis.blank?
      errors.add(:base, "Se requiere un diagnóstico o evaluación (campo A del SOAP)")
    end
  end
end
