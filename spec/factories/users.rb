FactoryBot.define do
  factory :user do
    association :organization
    first_name  { Faker::Name.first_name }
    last_name   { Faker::Name.last_name }
    sequence(:email) { |n| "user#{n}_#{Faker::Internet.username}@example.com" }
    password              { "Password123!" }
    password_confirmation { "Password123!" }
    role   { :admin }
    status { :active }

    trait :doctor do
      role { :doctor }
    end

    trait :receptionist do
      role { :receptionist }
    end

    trait :patient_role do
      role { :patient }
    end

    trait :inactive do
      status { :inactive }
    end
  end
end
