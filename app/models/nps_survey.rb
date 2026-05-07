class NpsSurvey < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :appointment

  before_validation :generate_token, on: :create

  validates :token, presence: true, uniqueness: true
  validates :score, numericality: { in: 1..10 }, allow_nil: true

  def submitted?
    submitted_at.present?
  end

  def submit!(score:, comment: nil)
    raise ActiveRecord::RecordInvalid, self if submitted?

    self.score        = score
    self.comment      = comment
    self.submitted_at = Time.current
    save!
  end

  private

  def generate_token
    self.token = loop do
      t = SecureRandom.urlsafe_base64(24)
      break t unless NpsSurvey.exists?(token: t)
    end
  end
end
