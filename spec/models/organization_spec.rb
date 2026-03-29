require 'rails_helper'

RSpec.describe Organization, type: :model do
  subject(:org) { build(:organization) }

  # --- Validaciones ---
  describe "validaciones" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:clinic_type) }
    it { should validate_presence_of(:timezone) }

    it "valida formato de email" do
      org.email = "no-es-un-email"
      expect(org).not_to be_valid
      expect(org.errors[:email]).to be_present
    end

    it "valida slug con solo letras minúsculas, números y guiones" do
      org.slug = "Slug Con Espacios"
      expect(org).not_to be_valid
    end
  end

  # --- Asociaciones ---
  describe "asociaciones" do
    it { should have_many(:users).dependent(:destroy) }
    it { should have_many(:appointments).dependent(:destroy) }
    it { should have_many(:patients).dependent(:destroy) }
  end

  # --- Enums ---
  describe "enums" do
    it { should define_enum_for(:plan).with_values(trial: 0, basic: 1, professional: 2, enterprise: 3) }
    it { should define_enum_for(:status).with_values(active: 0, inactive: 1, suspended: 2) }
  end

  # --- Generación automática de slug ---
  describe "generación de slug" do
    it "genera slug a partir del nombre" do
      org = build(:organization, name: "Clínica San José")
      org.valid?
      expect(org.slug).to eq("clinica-san-jose")
    end

    it "genera subdomain igual al slug" do
      org = build(:organization, name: "Mi Clínica")
      org.valid?
      expect(org.subdomain).to eq(org.slug)
    end
  end

  # --- Trial period ---
  describe "periodo de prueba" do
    it "establece trial_ends_at en 15 días al crear" do
      org = create(:organization)
      expect(org.trial_ends_at).to be_within(1.minute).of(15.days.from_now)
    end

    it "establece plan como trial al crear" do
      org = create(:organization)
      expect(org).to be_trial
    end
  end

  # --- Helpers de licencia ---
  describe "#trial_expired?" do
    it "retorna true si el trial expiró" do
      org = create(:organization, :trial_expired)
      expect(org.trial_expired?).to be true
    end

    it "retorna false si el trial está vigente" do
      org = create(:organization)
      expect(org.trial_expired?).to be false
    end
  end

  describe "#license_active?" do
    it "retorna true para org en trial vigente" do
      expect(create(:organization).license_active?).to be true
    end

    it "retorna false para org con trial expirado" do
      expect(create(:organization, :trial_expired).license_active?).to be false
    end

    it "retorna false para org suspendida" do
      expect(create(:organization, :suspended).license_active?).to be false
    end
  end

  describe "#enabled_features" do
    it "no incluye inventario en plan basic" do
      org = create(:organization, :basic)
      expect(org.enabled_features).not_to include("inventory")
    end

    it "incluye inventario en plan enterprise" do
      org = create(:organization, :enterprise)
      expect(org.enabled_features).to include("inventory")
    end
  end

  # --- Unicidad ---
  describe "unicidad" do
    it "no permite slugs duplicados" do
      existing = create(:organization)
      duplicate = build(:organization)
      duplicate.slug = existing.slug
      expect(duplicate).not_to be_valid
    end
  end
end
