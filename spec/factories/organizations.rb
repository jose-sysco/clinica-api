FactoryBot.define do
  factory :organization do
    name { "MyString" }
    slug { "MyString" }
    subdomain { "MyString" }
    email { "MyString" }
    phone { "MyString" }
    address { "MyString" }
    city { "MyString" }
    country { "MyString" }
    timezone { "MyString" }
    logo { "MyString" }
    clinic_type { 1 }
    status { 1 }
  end
end
