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
require 'rails_helper'

RSpec.describe Schedule, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
