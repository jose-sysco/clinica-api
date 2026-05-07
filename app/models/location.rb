class Location < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  has_many   :doctor_locations, dependent: :destroy
  has_many   :doctors,          through: :doctor_locations
  has_many   :appointments,     dependent: :nullify

  validates :name, presence: true

  scope :active, -> { where(active: true) }
end
