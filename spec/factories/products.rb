FactoryBot.define do
  factory :product do
    association :organization
    sequence(:name)  { |n| "#{Faker::Commerce.product_name} #{n}" }
    sequence(:sku)   { |n| "SKU-#{n.to_s.rjust(6, '0')}" }
    category         { "medicamento" }
    unit             { "unidad" }
    current_stock    { 50 }
    min_stock        { 10 }
    active           { true }

    trait :low_stock do
      current_stock { 5 }
      min_stock     { 10 }
    end

    trait :out_of_stock do
      current_stock { 0 }
      min_stock     { 10 }
    end

    trait :no_min_stock do
      min_stock { 0 }
    end

    trait :inactive do
      active { false }
    end
  end
end
