require 'rails_helper'

RSpec.describe Product, type: :model do
  let(:org) { create(:organization) }

  subject(:product) { build(:product, organization: org) }

  # --- Validaciones ---
  describe "validaciones" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:unit) }
    it { should validate_numericality_of(:current_stock).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:min_stock).is_greater_than_or_equal_to(0) }
  end

  # --- Asociaciones ---
  describe "asociaciones" do
    it { should belong_to(:organization) }
    it { should have_many(:stock_movements).dependent(:destroy) }
  end

  # --- #low_stock? ---
  describe "#low_stock?" do
    it "retorna true cuando current_stock <= min_stock y min_stock > 0" do
      product = build(:product, :low_stock, organization: org)
      expect(product.low_stock?).to be true
    end

    it "retorna false cuando current_stock > min_stock" do
      product = build(:product, current_stock: 50, min_stock: 10, organization: org)
      expect(product.low_stock?).to be false
    end

    it "retorna false cuando min_stock es 0 (sin umbral configurado)" do
      product = build(:product, :no_min_stock, current_stock: 0, organization: org)
      expect(product.low_stock?).to be false
    end

    it "retorna true cuando current_stock es exactamente igual a min_stock" do
      product = build(:product, current_stock: 10, min_stock: 10, organization: org)
      expect(product.low_stock?).to be true
    end
  end

  # --- Scopes ---
  describe "scopes" do
    before { ActsAsTenant.current_tenant = org }
    after  { ActsAsTenant.current_tenant = nil }

    it ".active retorna solo productos activos" do
      create(:product, organization: org, active: true)
      create(:product, :inactive, organization: org)
      expect(Product.active.count).to eq(1)
    end

    it ".low_stock retorna productos con stock bajo" do
      create(:product, :low_stock, organization: org)
      create(:product, current_stock: 50, min_stock: 10, organization: org)
      expect(Product.low_stock.count).to eq(1)
    end

    it ".by_name filtra por nombre (case insensitive)" do
      create(:product, name: "Amoxicilina 500mg", organization: org)
      create(:product, name: "Ibuprofeno 200mg", organization: org)
      expect(Product.by_name("amoxicilina").count).to eq(1)
    end
  end

  # --- Stock no puede ser negativo ---
  describe "stock no negativo" do
    it "no es válido con current_stock negativo" do
      product.current_stock = -1
      expect(product).not_to be_valid
    end
  end
end
