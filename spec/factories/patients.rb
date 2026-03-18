# == Schema Information
#
# Table name: patients
#
#  id              :bigint           not null, primary key
#  organization_id :integer          not null
#  owner_id        :integer          not null
#  name            :string           not null
#  patient_type    :integer          default("human"), not null
#  species         :string
#  breed           :string
#  gender          :integer          default("unknown"), not null
#  birthdate       :date
#  weight          :decimal(5, 2)
#  notes           :text
#  status          :integer          default("active"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
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
