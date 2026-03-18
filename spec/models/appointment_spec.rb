# == Schema Information
#
# Table name: appointments
#
#  id                  :bigint           not null, primary key
#  organization_id     :integer          not null
#  doctor_id           :integer          not null
#  patient_id          :integer          not null
#  owner_id            :integer          not null
#  scheduled_at        :datetime         not null
#  ends_at             :datetime         not null
#  status              :integer          default("pending"), not null
#  appointment_type    :integer          default("first_visit"), not null
#  reason              :text             not null
#  notes               :text
#  cancelled_by        :integer
#  cancellation_reason :text
#  confirmed_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
require 'rails_helper'

RSpec.describe Appointment, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
