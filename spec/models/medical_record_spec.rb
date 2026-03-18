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
require 'rails_helper'

RSpec.describe MedicalRecord, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
