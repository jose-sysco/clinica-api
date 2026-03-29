require 'rails_helper'

RSpec.describe User, type: :model do
  let(:org) { create(:organization) }

  subject(:user) { build(:user, organization: org) }

  # --- Validaciones ---
  describe "validaciones" do
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:role) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:email) }
  end

  # --- Asociaciones ---
  describe "asociaciones" do
    it { should belong_to(:organization) }
    it { should have_one(:doctor) }
    it { should have_one(:owner) }
    it { should have_many(:notifications) }
  end

  # --- Enums ---
  describe "enums" do
    it { should define_enum_for(:role).with_values(admin: 0, doctor: 1, receptionist: 2, patient: 3, superadmin: 4) }
    it { should define_enum_for(:status).with_values(active: 0, inactive: 1, banned: 2) }
  end

  # --- Helpers de instancia ---
  describe "#full_name" do
    it "devuelve nombre completo" do
      user.first_name = "Ana"
      user.last_name  = "López"
      expect(user.full_name).to eq("Ana López")
    end
  end

  describe "role helpers" do
    it "#admin? retorna true para admin" do
      expect(build(:user, organization: org, role: :admin).admin?).to be true
    end

    it "#doctor? retorna true para doctor" do
      expect(build(:user, :doctor, organization: org).doctor?).to be true
    end

    it "#admin? retorna false para doctor" do
      expect(build(:user, :doctor, organization: org).admin?).to be false
    end
  end

  # --- Scopes ---
  describe "scopes" do
    before do
      ActsAsTenant.current_tenant = org
      create(:user, organization: org, status: :active)
      create(:user, organization: org, status: :inactive)
      create(:user, :doctor, organization: org, status: :active)
    end

    after { ActsAsTenant.current_tenant = nil }

    it ".active_users retorna solo usuarios activos" do
      expect(User.active_users.count).to eq(2)
    end

    it ".doctors retorna solo doctores" do
      expect(User.doctors.count).to eq(1)
    end
  end

  # --- Email único ---
  describe "email único" do
    it "no permite emails duplicados dentro de la misma organización" do
      create(:user, organization: org, email: "test@example.com")
      duplicate = build(:user, organization: org, email: "test@example.com")
      expect(duplicate).not_to be_valid
    end
  end
end
