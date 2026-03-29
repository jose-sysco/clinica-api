FactoryBot.define do
  factory :appointment do
    association :organization
    association :owner
    # patient belongs_to owner — share the same org/owner
    patient      { association(:patient, organization: organization, owner: owner) }
    doctor       { association(:doctor, organization: organization) }
    appointment_type { :first_visit }
    reason       { Faker::Lorem.sentence }
    status       { :pending }
    # Default to next Monday at 10:00 — aligns with the schedule factory default
    scheduled_at do
      today      = Time.current
      days_ahead = 1 - today.wday   # 1 = Monday
      days_ahead += 7 if days_ahead <= 0
      (today + days_ahead.days).change(hour: 10, min: 0, sec: 0)
    end
    ends_at { scheduled_at ? scheduled_at + 30.minutes : nil }

    # Ensure the doctor has a schedule that covers the appointment slot
    before(:create) do |appt|
      day = appt.scheduled_at.wday
      ActsAsTenant.with_tenant(appt.organization) do
        unless appt.doctor.schedules.active.exists?(day_of_week: day)
          create(:schedule,
            organization: appt.organization,
            doctor:       appt.doctor,
            day_of_week:  day,
            start_time:   "08:00",
            end_time:     "18:00"
          )
        end
      end
    end

    trait :confirmed do
      status { :confirmed }
    end

    trait :completed do
      status { :completed }
    end

    trait :cancelled do
      status { :cancelled }
    end
  end
end
