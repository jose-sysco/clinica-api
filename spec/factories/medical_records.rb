# == Schema Information
#
# Table name: medical_records
#
#  id              :bigint           not null, primary key
#  organization_id :integer          not null
#  appointment_id  :integer          not null
#  patient_id      :integer          not null
#  doctor_id       :integer          not null
#  weight          :decimal(5, 2)
#  height          :decimal(5, 2)
#  temperature     :decimal(4, 1)
#  diagnosis       :text
#  treatment       :text
#  medications     :text
#  notes           :text
#  next_visit_date :date
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
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
