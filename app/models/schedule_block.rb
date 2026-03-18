# == Schema Information
#
# Table name: schedule_blocks
#
#  id              :bigint           not null, primary key
#  organization_id :integer          not null
#  doctor_id       :integer          not null
#  start_datetime  :datetime         not null
#  end_datetime    :datetime         not null
#  reason          :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class ScheduleBlock < ApplicationRecord
  # Multitenant
  acts_as_tenant :organization

  # Asociaciones
  belongs_to :organization
  belongs_to :doctor

  # Validaciones
  validates :start_datetime, presence: true
  validates :end_datetime,   presence: true
  validate  :end_datetime_after_start_datetime
  validate  :no_overlapping_blocks

  # Scopes
  scope :upcoming, -> { where("start_datetime >= ?", Time.current) }
  scope :for_range, ->(from, to) { where("start_datetime < ? AND end_datetime > ?", to, from) }

  private

  def end_datetime_after_start_datetime
    return if start_datetime.blank? || end_datetime.blank?

    if end_datetime <= start_datetime
      errors.add(:end_datetime, "debe ser posterior a la fecha de inicio")
    end
  end

  def no_overlapping_blocks
    return if start_datetime.blank? || end_datetime.blank?

    overlapping = ScheduleBlock.where(doctor_id: doctor_id)
                               .where.not(id: id)
                               .for_range(start_datetime, end_datetime)

    if overlapping.exists?
      errors.add(:base, "ya existe un bloqueo en ese rango de tiempo para este doctor")
    end
  end
end
