FactoryBot.define do
  factory :medical_record do
    organization_id { 1 }
    appointment_id { 1 }
    patient_id { 1 }
    doctor_id { 1 }
    weight { "9.99" }
    height { "9.99" }
    temperature { "9.99" }
    diagnosis { "MyText" }
    treatment { "MyText" }
    medications { "MyText" }
    notes { "MyText" }
    next_visit_date { "2026-03-15" }
  end
end
