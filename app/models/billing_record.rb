class BillingRecord < ApplicationRecord
  belongs_to :organization
  belongs_to :recorded_by, class_name: "User", foreign_key: :recorded_by_id

  validates :period,      presence: true
  validates :amount_paid, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :recorded_at, presence: true
  validates :organization_id, uniqueness: {
    scope: :period,
    message: "ya tiene un pago registrado para este período"
  }
end
