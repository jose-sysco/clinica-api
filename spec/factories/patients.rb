FactoryBot.define do
  factory :patient do
    organization_id { 1 }
    owner_id { 1 }
    name { "MyString" }
    patient_type { 1 }
    species { "MyString" }
    breed { "MyString" }
    gender { 1 }
    birthdate { "2026-03-12" }
    weight { "9.99" }
    notes { "MyText" }
    status { 1 }
  end
end
