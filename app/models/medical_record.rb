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

  has_many_attached :attachments

  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp application/pdf].freeze
  MAX_ATTACHMENT_SIZE   = 3.megabytes
  MAX_ATTACHMENTS       = 5

  validates :appointment_id, uniqueness: true
  validate  :validate_attachments

  private

  def validate_attachments
    return unless attachments.attached?

    if attachments.count > MAX_ATTACHMENTS
      errors.add(:attachments, "máximo #{MAX_ATTACHMENTS} archivos permitidos")
      return
    end

    attachments.each do |file|
      unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
        errors.add(:attachments, "solo se permiten imágenes (JPG, PNG, WebP) y PDFs")
      end
      if file.byte_size > MAX_ATTACHMENT_SIZE
        errors.add(:attachments, "#{file.filename} supera el límite de 3 MB")
      end
    end
  end

  # Vitales — todos opcionales, solo validación numérica si se proporcionan
  validates :weight,                   numericality: { greater_than: 0 },                             allow_blank: true
  validates :height,                   numericality: { greater_than: 0 },                             allow_blank: true
  validates :goal_weight,              numericality: { greater_than: 0 },                             allow_blank: true
  validates :temperature,              numericality: { greater_than: 0 },                             allow_blank: true
  validates :heart_rate,               numericality: { only_integer: true, greater_than: 0 },         allow_blank: true
  validates :respiratory_rate,         numericality: { only_integer: true, greater_than: 0 },         allow_blank: true
  validates :blood_pressure_systolic,  numericality: { only_integer: true, greater_than: 0 },         allow_blank: true
  validates :blood_pressure_diastolic, numericality: { only_integer: true, greater_than: 0 },         allow_blank: true
  validates :oxygen_saturation,        numericality: { greater_than: 0, less_than_or_equal_to: 100 }, allow_blank: true
  validates :pain_scale,               numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }, allow_blank: true
  validates :mood_scale,               numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }, allow_blank: true
  validates :session_number,           numericality: { only_integer: true, greater_than: 0 },         allow_blank: true
end
