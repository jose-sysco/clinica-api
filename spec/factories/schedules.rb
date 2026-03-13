FactoryBot.define do
  factory :schedule do
    organization_id { 1 }
    doctor_id { 1 }
    day_of_week { 1 }
    start_time { "2026-03-12 23:55:36" }
    end_time { "2026-03-12 23:55:36" }
    is_active { false }
  end
end
