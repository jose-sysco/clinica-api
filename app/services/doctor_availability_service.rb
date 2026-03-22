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

    now = Time.current

    slots.reject do |slot|
      booked?(slot, booked_slots) || blocked?(slot, blocked) || slot[:starts_at] <= now
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
    # Use Time.zone so the day window is in the org's local timezone, not UTC.
    day_start = Time.zone.parse(@date.to_s).beginning_of_day
    day_end   = Time.zone.parse(@date.to_s).end_of_day

    @doctor.appointments
           .where(status: [:pending, :confirmed, :in_progress, :completed])
           .where(scheduled_at: day_start..day_end)
           .pluck(:scheduled_at, :ends_at)
  end

  def find_blocked_ranges
    @doctor.schedule_blocks
           .for_range(@date.beginning_of_day, @date.end_of_day)
           .pluck(:start_datetime, :end_datetime)
  end

  def booked?(slot, booked_slots)
    slot_start = slot[:starts_at].utc
    slot_end   = slot[:ends_at].utc
    booked_slots.any? do |starts, ends|
      slot_start < ends.utc && slot_end > starts.utc
    end
  end

  def blocked?(slot, blocked_ranges)
    slot_start = slot[:starts_at].utc
    slot_end   = slot[:ends_at].utc
    blocked_ranges.any? do |starts, ends|
      slot_start < ends.utc && slot_end > starts.utc
    end
  end
end