# == Schema Information
#
# Table name: schedules
#
#  id              :bigint           not null, primary key
#  organization_id :integer          not null
#  doctor_id       :integer          not null
#  day_of_week     :integer          not null
#  start_time      :time             not null
#  end_time        :time             not null
#  is_active       :boolean          default(TRUE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class Schedule < ApplicationRecord
  # Multitenant
  acts_as_tenant :organization

  # Asociaciones
  belongs_to :organization
  belongs_to :doctor
  belongs_to :location, optional: true

  # Enums
  enum :day_of_week, { sunday: 0, monday: 1, tuesday: 2, wednesday: 3, thursday: 4, friday: 5, saturday: 6 }

  # Validaciones
  validates :day_of_week, presence: true
  validates :start_time,  presence: true
  validates :end_time,    presence: true
  validates :day_of_week, uniqueness: { scope: [:doctor_id, :location_id], message: "ya tiene un horario este día para esta sede" }
  validate  :end_time_after_start_time
  validate  :no_cross_location_overlap

  # Scopes
  scope :active, -> { where(is_active: true) }

  private

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?
    errors.add(:end_time, "debe ser posterior a la hora de inicio") if end_time <= start_time
  end

  # Un doctor no puede tener horarios activos que se crucen entre distintas sedes el mismo día.
  def no_cross_location_overlap
    return unless is_active?
    return if start_time.blank? || end_time.blank? || day_of_week.blank? || doctor_id.blank?

    conflicting = doctor.schedules
                        .active
                        .where(day_of_week: day_of_week)
                        .where.not(id: id)
                        .where.not(location_id: location_id)
                        .select { |s| times_overlap?(s.start_time, s.end_time) }

    if conflicting.any?
      day_names_es = {
        "sunday" => "Domingo", "monday" => "Lunes", "tuesday" => "Martes",
        "wednesday" => "Miércoles", "thursday" => "Jueves",
        "friday" => "Viernes", "saturday" => "Sábado"
      }
      sede = conflicting.first.location&.name || "horario general"
      errors.add(:base,
        "Horario cruzado en #{day_names_es[day_of_week.to_s]}: " \
        "el especialista ya atiende en '#{sede}' en ese mismo horario. " \
        "Un especialista no puede estar en dos sedes al mismo tiempo."
      )
    end
  end

  def times_overlap?(other_start, other_end)
    s1 = mins(start_time)
    e1 = mins(end_time)
    s2 = mins(other_start)
    e2 = mins(other_end)
    s1 < e2 && e1 > s2
  end

  def mins(t)
    t.hour * 60 + t.min
  end
end
