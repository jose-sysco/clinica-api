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
