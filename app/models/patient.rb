class Patient < ApplicationRecord
  # Multitenant
  acts_as_tenant :organization

  # Asociaciones
  belongs_to :organization
  belongs_to :owner
  has_many   :appointments, dependent: :destroy

  # Enums
  enum patient_type: {
    human:  0,
    animal: 1
  }

  enum gender: {
    unknown: 0,
    male:    1,
    female:  2
  }

  enum status: {
    active:   0,
    inactive: 1,
    deceased: 2
  }

  # Validaciones
  validates :name,         presence: true
  validates :patient_type, presence: true
  validates :gender,       presence: true
  validates :status,       presence: true
  validates :weight,       numericality: { greater_than: 0 }, allow_blank: true
  validate  :animal_fields_present_if_animal

  # Scopes
  scope :active,   -> { where(status: :active) }
  scope :animals,  -> { where(patient_type: :animal) }
  scope :humans,   -> { where(patient_type: :human) }
  scope :search,   ->(query) { where("name ILIKE ?", "%#{query}%") }

  # Helpers
  def age
    return nil if birthdate.blank?
    ((Time.current.to_date - birthdate) / 365).floor
  end

  def animal?
    patient_type == "animal"
  end

  def human?
    patient_type == "human"
  end

  private

  def animal_fields_present_if_animal
    return unless animal?

    if species.blank?
      errors.add(:species, "es requerida para pacientes animales")
    end
  end
end