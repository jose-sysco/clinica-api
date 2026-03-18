# == Schema Information
#
# Table name: organizations
#
#  id          :bigint           not null, primary key
#  name        :string           not null
#  slug        :string           not null
#  subdomain   :string           not null
#  email       :string           not null
#  phone       :string
#  address     :string
#  city        :string
#  country     :string
#  timezone    :string           default("UTC"), not null
#  logo        :string
#  clinic_type :integer          default("veterinary"), not null
#  status      :integer          default("active"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'rails_helper'

RSpec.describe Organization, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
