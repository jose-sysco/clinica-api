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
FactoryBot.define do
  factory :owner do
    organization_id { 1 }
    user_id { 1 }
    first_name { "MyString" }
    last_name { "MyString" }
    email { "MyString" }
    phone { "MyString" }
    address { "MyString" }
    identification { "MyString" }
  end
end
