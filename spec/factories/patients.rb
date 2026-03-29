FactoryBot.define do
  factory :patient do
    association :organization
    association :owner
    name         { Faker::Name.name }
    patient_type { :human }
    gender       { :unknown }
    birthdate    { Faker::Date.birthday(min_age: 1, max_age: 80) }
    status       { :active }

    trait :animal do
      patient_type { :animal }
      species      { "Canino" }
      breed        { "Labrador" }
      gender       { :male }
    end
  end
end
