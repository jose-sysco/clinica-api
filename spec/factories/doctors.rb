FactoryBot.define do
  factory :doctor do
    organization_id { 1 }
    user_id { 1 }
    specialty { "MyString" }
    license_number { "MyString" }
    bio { "MyText" }
    consultation_duration { 1 }
    status { 1 }
  end
end
