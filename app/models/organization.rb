class Organization < ApplicationRecord
  # Multitenant
  has_many :users,          dependent: :destroy
  has_many :doctors,        dependent: :destroy
  has_many :schedules,      dependent: :destroy
  has_many :schedule_blocks, dependent: :destroy
  has_many :owners,         dependent: :destroy
  has_many :patients,       dependent: :destroy
  has_many :appointments,   dependent: :destroy
  has_many :notifications,  dependent: :destroy

  # Enums
  enum :clinic_type, { veterinary: 0, pediatric: 1, general: 2, dental: 3 }
  enum :status, { active: 0, inactive: 1, suspended: 2 }

  # Validaciones
  validates :name,      presence: true
  validates :slug,      presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/, message: "solo letras minúsculas, números y guiones" }
  validates :subdomain, presence: true, uniqueness: true
  validates :email,     presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :clinic_type, presence: true
  validates :status,      presence: true
  validates :timezone,    presence: true

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  private

  def generate_slug
    self.slug = name
      .unicode_normalize(:nfd)
      .gsub(/\p{Mn}/, '')
      .downcase
      .gsub(/[^a-z0-9\s\-]/, '')
      .gsub(/\s+/, '-')
      .gsub(/-+/, '-')
      .strip
  end
end