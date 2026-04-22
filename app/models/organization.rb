# == Schema Information
#
# Table name: organizations
#
#  id             :bigint           not null, primary key
#  name           :string           not null
#  slug           :string           not null
#  subdomain      :string           not null
#  email          :string           not null
#  phone          :string
#  address        :string
#  city           :string
#  country        :string
#  timezone       :string           default("America/Guatemala"), not null
#  logo           :string
#  clinic_type    :integer          default("veterinary"), not null
#  status         :integer          default("active"), not null
#  plan           :integer          default("trial"), not null
#  trial_ends_at  :datetime
#  suspended_at   :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Organization < ApplicationRecord
  # Logo upload
  has_one_attached :logo_file

  # Multitenant
  has_many :users,           dependent: :destroy
  has_many :doctors,         dependent: :destroy
  has_many :schedules,       dependent: :destroy
  has_many :schedule_blocks, dependent: :destroy
  has_many :owners,          dependent: :destroy
  has_many :patients,        dependent: :destroy
  has_many :appointments,    dependent: :destroy
  has_many :notifications,        dependent: :destroy
  has_many :license_change_logs,  dependent: :destroy

  # Enums
  enum :clinic_type, { veterinary: 0, pediatric: 1, general: 2, dental: 3, psychology: 4, physiotherapy: 5, nutrition: 6, beauty: 7, coaching: 8, legal: 9, fitness: 10 }
  enum :status,      { active: 0, inactive: 1, suspended: 2 }
  enum :plan,        { trial: 0, basic: 1, professional: 2, enterprise: 3 }

  # Validaciones
  validates :name,       presence: true
  validates :slug,       presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/, message: "solo letras minúsculas, números y guiones" }
  validates :subdomain,  presence: true, uniqueness: true
  validates :email,      presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :clinic_type, presence: true
  validates :status,      presence: true
  validates :timezone,    presence: true

  # Callbacks
  before_validation :generate_slug,      if: -> { slug.blank? && name.present? }
  before_validation :generate_subdomain, if: -> { subdomain.blank? && name.present? }
  before_create     :set_trial_period
  before_create     :lock_plan_price

  # --- Helpers de licencia ---

  def expiring_soon?(days = 7)
    trial? && trial_ends_at.present? && trial_ends_at.between?(Time.current, days.days.from_now)
  end

  def trial_expired?
    trial? && trial_ends_at.present? && trial_ends_at < Time.current
  end

  def trial_days_remaining
    return 0 unless trial? && trial_ends_at.present?
    days = ((trial_ends_at - Time.current) / 1.day).ceil
    [ days, 0 ].max
  end

  def enabled_features
    PlanConfiguration.features_for(plan)
  end

  def license_active?
    return false if suspended?
    return false if trial_expired?
    true
  end

  private

  def set_trial_period
    # La org de administración del sistema nunca tiene trial
    return if slug == "sistema-superadmin"
    self.trial_ends_at = 15.days.from_now
    self.plan = :trial
  end

  def generate_slug
    self.slug = name
      .unicode_normalize(:nfd)
      .gsub(/\p{Mn}/, "")
      .downcase
      .gsub(/[^a-z0-9\s\-]/, "")
      .gsub(/\s+/, "-")
      .gsub(/-+/, "-")
      .strip
  end

  def generate_subdomain
    self.subdomain = slug
  end

  # Fija el precio vigente del plan al momento del registro.
  # Clientes existentes conservan su precio aunque el plan cambie
  # de precio en el futuro.
  def lock_plan_price
    config = PlanConfiguration.find_by(plan: plan)
    return unless config

    self.locked_price_monthly     = config.price_monthly
    self.locked_price_monthly_usd = config.price_monthly_usd
  end
end
