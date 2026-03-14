class DoctorAvailabilityService
  def initialize(doctor, date)
    @doctor = doctor
    @date   = date.is_a?(String) ? Date.parse(date) : date
  end

  def call
    schedule = find_schedule
    return [] unless schedule

    slots        = generate_slots(schedule)
    booked_slots = find_booked_slots
    blocked      = find_blocked_ranges

    slots.reject do |slot|
      booked?(slot, booked_slots) || blocked?(slot, blocked)
    end
  end

  private

  def find_schedule
    @doctor.schedules.active.find_by(day_of_week: @date.wday)
  end

  def generate_slots(schedule)
    slots    = []
    duration = @doctor.consultation_duration.minutes
    current  = Time.zone.parse("#{@date} #{schedule.start_time.strftime('%H:%M')}")
    end_time = Time.zone.parse("#{@date} #{schedule.end_time.strftime('%H:%M')}")

    while current + duration <= end_time
      slots << { starts_at: current, ends_at: current + duration }
      current += duration
    end

    slots
  end

  def find_booked_slots
    @doctor.appointments
           .where(status: [:pending, :confirmed, :in_progress])
           .where(scheduled_at: @date.beginning_of_day..@date.end_of_day)
           .pluck(:scheduled_at, :ends_at)
  end

  def find_blocked_ranges
    @doctor.schedule_blocks
           .for_range(@date.beginning_of_day, @date.end_of_day)
           .pluck(:start_datetime, :end_datetime)
  end

  def booked?(slot, booked_slots)
    booked_slots.any? do |starts, ends|
      slot[:starts_at] < ends && slot[:ends_at] > starts
    end
  end

  def blocked?(slot, blocked_ranges)
    blocked_ranges.any? do |starts, ends|
      slot[:starts_at] < ends && slot[:ends_at] > starts
    end
  end
end