# == Schema Information
#
# Table name: doctors
#
#  id                    :bigint           not null, primary key
#  organization_id       :integer          not null
#  user_id               :integer          not null
#  specialty             :string           not null
#  license_number        :string
#  bio                   :text
#  consultation_duration :integer          default(30), not null
#  status                :integer          default("active"), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
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
