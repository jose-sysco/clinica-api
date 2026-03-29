FactoryBot.define do
  factory :doctor do
    association :organization
    # Creates a user with role :doctor in the same organization
    user { association(:user, :doctor, organization: organization) }
    specialty             { Faker::Job.field }
    sequence(:license_number) { |n| "LIC-#{n.to_s.rjust(6, '0')}" }
    bio                   { Faker::Lorem.sentence }
    consultation_duration { 30 }
    status                { :active }

    trait :on_leave do
      status { :on_leave }
    end

    trait :no_inventory do
      after(:create) { |d| d.update_columns(inventory_movements: false) }
    end

    trait :with_inventory do
      after(:create) { |d| d.update_columns(inventory_movements: true) }
    end
  end
end
