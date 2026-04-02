# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  organization_id        :integer          not null
#  first_name             :string           not null
#  last_name              :string           not null
#  phone                  :string
#  role                   :integer          default("admin"), not null
#  status                 :integer          default("active"), not null
#  avatar                 :string
#
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
  has_many   :notifications

  # Enums
  enum :role,   { admin: 0, doctor: 1, receptionist: 2, patient: 3, superadmin: 4 }
  enum :status, { active: 0, inactive: 1, banned: 2 }

  # Validaciones
  validates :first_name, presence: true
  validates :last_name,  presence: true
  validates :role,       presence: true
  validates :status,     presence: true

  # Callbacks
  before_create :generate_email_verification_token

  # Scopes
  scope :active_users, -> { where(status: :active) }
  scope :doctors,      -> { where(role: :doctor) }
  scope :patients,     -> { where(role: :patient) }

  # Helpers
  def email_verified?
    email_verified_at.present?
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def admin?
    role == "admin"
  end

  def doctor?
    role == "doctor"
  end

  def receptionist?
    role == "receptionist"
  end

  def patient?
    role == "patient"
  end

  def superadmin?
    role == "superadmin"
  end

  def active_user?
    status == "active"
  end

  private

  def generate_email_verification_token
    return if email_verified_at.present?
    self.email_verification_token = SecureRandom.urlsafe_base64(32)
  end
end
