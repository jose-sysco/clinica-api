class Salesperson < ApplicationRecord
  self.table_name = "salespersons"

  PLANS = %w[basic professional enterprise].freeze

  has_many :organizations,         dependent: :nullify
  has_many :salesperson_payments,  dependent: :destroy

  validates :name, presence: true

  scope :active, -> { where(active: true) }

  def commission_for_plan(plan)
    commission_by_plan[plan.to_s]&.to_f || 0.0
  end
end
