class StockMovement < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :product
  belongs_to :user
  belongs_to :doctor,         optional: true
  belongs_to :medical_record, optional: true

  enum :movement_type, { entry: 0, exit: 1, adjustment: 2 }

  validates :quantity,      presence: true, numericality: { other_than: 0 }
  validates :movement_type, presence: true
  validates :stock_before,  presence: true
  validates :stock_after,   presence: true

  before_validation :set_stock_snapshot, on: :create
  after_create      :update_product_stock

  private

  def set_stock_snapshot
    self.stock_before = product&.current_stock || 0
    case movement_type&.to_sym
    when :entry
      self.stock_after = stock_before + quantity.abs
    when :exit
      self.stock_after = stock_before - quantity.abs
    when :adjustment
      # quantity IS the new target stock
      self.stock_after = quantity
    end
  end

  def update_product_stock
    product.update_column(:current_stock, stock_after)
  end
end
