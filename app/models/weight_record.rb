class WeightRecord < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :patient

  validates :weight,      presence: true, numericality: { greater_than: 0 }
  validates :recorded_on, presence: true

  scope :chronological, -> { order(:recorded_on) }
  scope :recent,        -> { order(recorded_on: :desc) }
end
