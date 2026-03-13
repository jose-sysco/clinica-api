class User < ApplicationRecord
  # Devise
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  # Multitenant
  acts_as_tenant :organization

  # Asociaciones
  belongs_to :organization
  has_one    :doctor
  has_one    :owner

  # Enums
  enum :role, { admin: 0, doctor: 1, receptionist: 2, patient: 3 }
  enum :status, { active: 0, inactive: 1, banned: 2 }

  # Validaciones
  validates :first_name, presence: true
  validates :last_name,  presence: true
  validates :role,       presence: true
  validates :status,     presence: true

  # Scopes
  scope :active,   -> { where(status: :active) }
  scope :doctors,  -> { where(role: :doctor) }
  scope :patients, -> { where(role: :patient) }

  # Helpers
  def full_name
    "#{first_name} #{last_name}"
  end

  def active?
    status == "active"
  end
end