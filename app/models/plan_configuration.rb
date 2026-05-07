class PlanConfiguration < ApplicationRecord
  FEATURES = {
    # ── Core (todos los planes) ──────────────────────────────────────────────
    "appointments"     => { label: "Gestión de citas",            category: "core" },
    "medical_records"  => { label: "Expedientes médicos",         category: "core" },
    "notifications"    => { label: "Notificaciones internas",     category: "core" },
    # ── Basic+ ──────────────────────────────────────────────────────────────
    "reports"          => { label: "Reportes y estadísticas",     category: "core" },
    "public_booking"   => { label: "Reserva pública en línea",    category: "core" },
    "digital_admission"=> { label: "Admisión digital",            category: "core" },
    # ── Professional+ ───────────────────────────────────────────────────────
    "multi_doctor"     => { label: "Múltiples doctores",          category: "team" },
    "nps_surveys"      => { label: "Encuestas NPS post-cita",     category: "team" },
    "attachments"      => { label: "Adjuntos en expediente",      category: "team" },
    "prescriptions"    => { label: "Recetas electrónicas con QR", category: "team" },
    "multi_location"   => { label: "Multi-sede / sucursales",     category: "team" },
    # ── Enterprise ──────────────────────────────────────────────────────────
    "inventory"        => { label: "Inventario de productos",     category: "advanced" },
    "custom_branding"  => { label: "Marca personalizada",         category: "advanced" },
    "backup_export"    => { label: "Backup exportable",           category: "advanced" }
  }.freeze

  PLAN_DEFAULTS = {
    "trial"        => %w[appointments medical_records notifications],
    "basic"        => %w[appointments medical_records notifications
                         reports public_booking digital_admission],
    "professional" => %w[appointments medical_records notifications
                         reports public_booking digital_admission
                         multi_doctor nps_surveys attachments prescriptions multi_location],
    "enterprise"   => FEATURES.keys
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
