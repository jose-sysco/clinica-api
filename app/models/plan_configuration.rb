class PlanConfiguration < ApplicationRecord
  FEATURES = {
    "appointments"           => { label: "Gestión de citas",            category: "core" },
    "medical_records"        => { label: "Expedientes médicos",         category: "core" },
    "notifications"          => { label: "Notificaciones internas",     category: "core" },
    "reports"                => { label: "Reportes y estadísticas",     category: "core" },
    "whatsapp_notifications" => { label: "Notificaciones por WhatsApp", category: "communication" },
    "multi_doctor"           => { label: "Múltiples doctores",          category: "team" },
    "inventory"              => { label: "Inventario de medicinas",     category: "advanced" },
    "custom_branding"        => { label: "Marca personalizada",         category: "advanced" },
  }.freeze

  PLAN_DEFAULTS = {
    "trial"        => %w[appointments medical_records notifications],
    "basic"        => %w[appointments medical_records notifications reports],
    "professional" => %w[appointments medical_records notifications reports whatsapp_notifications multi_doctor],
    "enterprise"   => FEATURES.keys,
  }.freeze

  enum :plan, { trial: 0, basic: 1, professional: 2, enterprise: 3 }

  serialize :features, coder: JSON

  validates :plan,  presence: true, uniqueness: true
  validates :name,  presence: true

  def self.features_for(plan_key)
    config = ActsAsTenant.without_tenant { find_by(plan: plan_key) }
    config&.features || PLAN_DEFAULTS[plan_key.to_s] || []
  end
end
