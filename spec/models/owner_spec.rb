# == Schema Information
#
# Table name: owners
#
#  id              :bigint           not null, primary key
#  organization_id :integer          not null
#  user_id         :integer
#  first_name      :string           not null
#  last_name       :string           not null
#  email           :string
#  phone           :string           not null
#  address         :string
#  identification  :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
require 'rails_helper'

RSpec.describe Owner, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
