# == Schema Information
#
# Table name: waitlist_entries
#
#  id              :bigint           not null, primary key
#  organization_id :integer          not null
#  doctor_id       :integer          not null
#  patient_id      :integer          not null
#  owner_id        :integer          not null
#  preferred_date  :date
#  notes           :text
#  status          :integer          default(0), not null
#  notified_at     :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class WaitlistEntry < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :doctor
  belongs_to :patient
  belongs_to :owner

  enum :status, { waiting: 0, notified: 1, booked: 2, expired: 3 }

  validates :doctor_id,  presence: true
  validates :patient_id, presence: true
  validates :owner_id,   presence: true
  validates :status,     presence: true

  validate :patient_not_already_waiting

  scope :active,      -> { where(status: [ :waiting, :notified ]) }
  scope :for_doctor,  ->(doctor_id) { where(doctor_id: doctor_id) }
  scope :for_patient, ->(patient_id) { where(patient_id: patient_id) }
  scope :by_date,     ->(date) { where(preferred_date: date) }

  # Posición en la fila (1-based) respecto al doctor
  def position
    WaitlistEntry
      .where(organization_id: organization_id, doctor_id: doctor_id, status: :waiting)
      .where("created_at <= ?", created_at)
      .count
  end

  def notify!
    update!(status: :notified, notified_at: Time.current)
  end

  private

  def patient_not_already_waiting
    return if new_record? == false && !status_changed?

    existing = WaitlistEntry
      .where(organization_id: organization_id, doctor_id: doctor_id, patient_id: patient_id)
      .where(status: [ :waiting, :notified ])
      .where.not(id: id)

    errors.add(:base, "el paciente ya está en lista de espera con este doctor") if existing.exists?
  end
end
