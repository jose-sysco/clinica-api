FactoryBot.define do
  factory :schedule_block do
    organization_id { 1 }
    doctor_id { 1 }
    start_datetime { "2026-03-12 23:56:31" }
    end_datetime { "2026-03-12 23:56:31" }
    reason { "MyString" }
  end
end
