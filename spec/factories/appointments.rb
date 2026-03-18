# == Schema Information
#
# Table name: appointments
#
#  id                  :bigint           not null, primary key
#  organization_id     :integer          not null
#  doctor_id           :integer          not null
#  patient_id          :integer          not null
#  owner_id            :integer          not null
#  scheduled_at        :datetime         not null
#  ends_at             :datetime         not null
#  status              :integer          default("pending"), not null
#  appointment_type    :integer          default("first_visit"), not null
#  reason              :text             not null
#  notes               :text
#  cancelled_by        :integer
#  cancellation_reason :text
#  confirmed_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
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
