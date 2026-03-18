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
require 'rails_helper'

RSpec.describe Doctor, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
