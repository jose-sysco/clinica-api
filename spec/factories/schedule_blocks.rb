# == Schema Information
#
# Table name: schedule_blocks
#
#  id              :bigint           not null, primary key
#  organization_id :integer          not null
#  doctor_id       :integer          not null
#  start_datetime  :datetime         not null
#  end_datetime    :datetime         not null
#  reason          :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
FactoryBot.define do
  factory :schedule_block do
    organization_id { 1 }
    doctor_id { 1 }
    start_datetime { "2026-03-12 23:56:31" }
    end_datetime { "2026-03-12 23:56:31" }
    reason { "MyString" }
  end
end
