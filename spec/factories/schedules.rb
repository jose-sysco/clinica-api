# == Schema Information
#
# Table name: schedules
#
#  id              :bigint           not null, primary key
#  organization_id :integer          not null
#  doctor_id       :integer          not null
#  day_of_week     :integer          not null
#  start_time      :time             not null
#  end_time        :time             not null
#  is_active       :boolean          default(TRUE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
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
