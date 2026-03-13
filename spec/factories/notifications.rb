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
