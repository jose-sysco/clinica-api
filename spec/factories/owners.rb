FactoryBot.define do
  factory :owner do
    association :organization
    first_name     { Faker::Name.first_name }
    last_name      { Faker::Name.last_name }
    sequence(:email) { |n| "owner#{n}@example.com" }
    phone          { Faker::PhoneNumber.phone_number }
    address        { Faker::Address.street_address }
    identification { Faker::Alphanumeric.unique.alphanumeric(number: 10) }
  end
end
