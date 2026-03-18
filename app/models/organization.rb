# == Schema Information
#
# Table name: organizations
#
#  id          :bigint           not null, primary key
#  name        :string           not null
#  slug        :string           not null
#  subdomain   :string           not null
#  email       :string           not null
#  phone       :string
#  address     :string
#  city        :string
#  country     :string
#  timezone    :string           default("UTC"), not null
#  logo        :string
#  clinic_type :integer          default("veterinary"), not null
#  status      :integer          default("active"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
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
  before_validation :generate_subdomain, if: -> { subdomain.blank? && name.present? }

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

  def generate_subdomain
    self.subdomain = slug
  end
end
