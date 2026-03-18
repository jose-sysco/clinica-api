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
require 'rails_helper'

RSpec.describe Patient, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
