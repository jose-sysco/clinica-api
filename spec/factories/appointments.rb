FactoryBot.define do
  factory :appointment do
    organization_id { 1 }
    doctor_id { 1 }
    patient_id { 1 }
    owner_id { 1 }
    scheduled_at { "2026-03-13 00:00:39" }
    ends_at { "2026-03-13 00:00:39" }
    status { 1 }
    appointment_type { 1 }
    reason { "MyText" }
    notes { "MyText" }
    cancelled_by { 1 }
    cancellation_reason { "MyText" }
    confirmed_at { "2026-03-13 00:00:39" }
  end
end
