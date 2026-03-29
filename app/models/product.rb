class Product < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  has_many   :stock_movements, dependent: :destroy

  validates :name,          presence: true
  validates :unit,          presence: true
  validates :current_stock, numericality: { greater_than_or_equal_to: 0 }
  validates :min_stock,     numericality: { greater_than_or_equal_to: 0 }

  scope :active,       -> { where(active: true) }
  scope :low_stock,    -> { where("current_stock <= min_stock AND min_stock > 0") }
  scope :by_name,      ->(q) { where("name ILIKE ?", "%#{q}%") }
  scope :by_category,  ->(c) { where(category: c) }

  def low_stock?
    min_stock > 0 && current_stock <= min_stock
  end

  def expiring_soon
    stock_movements
      .entry
      .where("expiration_date IS NOT NULL AND expiration_date <= ?", 30.days.from_now)
      .where("expiration_date >= ?", Date.today)
      .order(:expiration_date)
  end

  def expired_batches
    stock_movements
      .entry
      .where("expiration_date IS NOT NULL AND expiration_date < ?", Date.today)
      .order(:expiration_date)
  end
end
