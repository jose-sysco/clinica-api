FactoryBot.define do
  factory :schedule do
    association :organization
    association :doctor
    day_of_week { :monday }
    start_time  { "08:00" }
    end_time    { "18:00" }
    is_active   { true }

    # Traits for each day of the week
    %i[sunday monday tuesday wednesday thursday friday saturday].each do |day|
      trait day do
        day_of_week { day }
      end
    end
  end
end
