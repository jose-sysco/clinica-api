# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  organization_id        :integer          not null
#  first_name             :string           not null
#  last_name              :string           not null
#  phone                  :string
#  role                   :integer          default("admin"), not null
#  status                 :integer          default("active"), not null
#  avatar                 :string
#
FactoryBot.define do
  factory :user do
  end
end
