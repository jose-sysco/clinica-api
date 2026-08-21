# == Schema Information
#
# Table name: prescriptions
#
#  id                  :bigint           not null, primary key
#  organization_id     :integer          not null
#  doctor_id           :integer          not null
#  patient_id          :integer          not null
#  appointment_id      :integer
#  medical_record_id   :integer
#  verification_token  :string           not null, unique
#  status              :string           not null, default: "active"
#  medications         :jsonb            not null, default: []
#  diagnosis           :text
#  notes               :text
#  issued_at           :date             not null
#  valid_until         :date
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
class Prescription < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :doctor
  belongs_to :patient
  belongs_to :appointment, optional: true
  belongs_to :medical_record, optional: true

  enum :status, { active: "active", revoked: "revoked" }

  before_create :set_verification_token
  before_create :set_issued_at

  validates :medications, presence: true
  validate  :medications_format

  scope :recent, -> { order(issued_at: :desc) }

  # La verificación por QR abre una página del frontend (Next.js), no del API.
  def public_url
    base = ENV.fetch("FRONTEND_URL", "http://localhost:3000").chomp("/")
    "#{base}/recetas/#{verification_token}"
  end

  private

  def set_verification_token
    self.verification_token = SecureRandom.hex(16)
  end

  def set_issued_at
    self.issued_at ||= Date.current
  end

  def medications_format
    return if medications.blank?
    unless medications.is_a?(Array) && medications.all? { |m| m.is_a?(Hash) && m["name"].present? }
      errors.add(:medications, "formato inválido — debe ser un array de medicamentos con campo 'name'")
    end
  end
end
