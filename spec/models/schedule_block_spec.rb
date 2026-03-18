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
require 'rails_helper'

RSpec.describe ScheduleBlock, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
