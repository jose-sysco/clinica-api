# == Schema Information
#
# Table name: owners
#
#  id              :bigint           not null, primary key
#  organization_id :integer          not null
#  user_id         :integer
#  first_name      :string           not null
#  last_name       :string           not null
#  email           :string
#  phone           :string           not null
#  address         :string
#  identification  :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class Owner < ApplicationRecord
  # Multitenant
  acts_as_tenant :organization

  # Asociaciones
  belongs_to :organization
  belongs_to :user, optional: true
  has_many   :patients,     dependent: :destroy
  has_many   :appointments, dependent: :destroy

  # Validaciones
  validates :first_name,      presence: true
  validates :last_name,       presence: true
  validates :phone,           presence: true
  validates :identification,  uniqueness: { scope: :organization_id, allow_blank: true }
  validates :email,           uniqueness: { scope: :organization_id, allow_blank: true },
                              format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }

  # Scopes
  scope :search, ->(query) {
    where("first_name ILIKE :q OR last_name ILIKE :q OR email ILIKE :q OR phone ILIKE :q", q: "%#{query}%")
  }

  # Helpers
  def full_name
    "#{first_name} #{last_name}"
  end
end
