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
require 'rails_helper'

RSpec.describe Notification, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
