# == Schema Information
#
# Table name: notifications
#
#  id                :bigint           not null, primary key
#  organization_id   :integer          not null
#  user_id           :integer          not null
#  appointment_id    :integer          not null
#  notification_type :integer          default("confirmation"), not null
#  channel           :integer          default("email"), not null
#  status            :integer          default("pending"), not null
#  sent_at           :datetime
#  read_at           :datetime
#  message           :text             not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
FactoryBot.define do
  factory :notification do
    organization_id { 1 }
    user_id { 1 }
    appointment_id { 1 }
    notification_type { 1 }
    channel { 1 }
    status { 1 }
    sent_at { "2026-03-13 00:01:54" }
    read_at { "2026-03-13 00:01:54" }
    message { "MyText" }
  end
end
