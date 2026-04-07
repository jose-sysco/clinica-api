class Payment < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :appointment
  belongs_to :recorded_by, class_name: "User"

  enum :payment_method, { cash: 0, card: 1, transfer: 2, other: 3 }

  validates :amount,         presence: true, numericality: { greater_than: 0 }
  validates :payment_method, presence: true

  scope :by_method,    ->(m)    { where(payment_method: m) }
  scope :by_date_range, ->(from, to) { where(created_at: from.beginning_of_day..to.end_of_day) }
end
