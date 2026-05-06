class SalespersonPayment < ApplicationRecord
  belongs_to :salesperson
  belongs_to :paid_by, class_name: "User", optional: true

  validates :period, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :salesperson_id, uniqueness: { scope: :period, message: "ya tiene un registro para este período" }

  scope :paid,   -> { where.not(paid_at: nil) }
  scope :unpaid, -> { where(paid_at: nil) }

  def paid?
    paid_at.present?
  end
end
