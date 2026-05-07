class AdmissionForm < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :appointment

  before_validation :generate_token, on: :create

  validates :token, presence: true, uniqueness: true

  def submitted?
    submitted_at.present?
  end

  def submit!(attrs)
    assign_attributes(attrs.slice(:allergies, :current_medications, :medical_history,
                                  :notes, :patient_dob))
    self.submitted_at = Time.current
    save!
  end

  private

  def generate_token
    self.token = loop do
      t = SecureRandom.urlsafe_base64(24)
      break t unless AdmissionForm.exists?(token: t)
    end
  end
end
