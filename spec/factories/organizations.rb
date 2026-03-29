FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "#{Faker::Company.name} #{n}" }
    email      { Faker::Internet.unique.email }
    phone      { Faker::PhoneNumber.phone_number }
    city       { "Guatemala" }
    country    { "Guatemala" }
    timezone   { "America/Guatemala" }
    clinic_type { :veterinary }
    status     { :active }
    # slug & subdomain are auto-generated from name via before_validation callbacks
    # plan is set to :trial by before_create callback

    trait :general do
      clinic_type { :general }
    end

    # Use update_columns to bypass the before_create callback that forces :trial
    trait :basic do
      after(:create) { |org| org.update_columns(plan: 1) }
    end

    trait :professional do
      after(:create) { |org| org.update_columns(plan: 2) }
    end

    trait :enterprise do
      after(:create) { |org| org.update_columns(plan: 3) }
    end

    trait :trial_expired do
      after(:create) { |org| org.update_columns(trial_ends_at: 2.days.ago) }
    end

    trait :suspended do
      after(:create) { |org| org.update_columns(status: 2, suspended_at: Time.current) }
    end
  end
end
