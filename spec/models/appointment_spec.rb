require 'rails_helper'

RSpec.describe Appointment, type: :model do
  let(:org)   { create(:organization) }
  let(:owner) { create(:owner, organization: org) }
  let(:patient) { create(:patient, organization: org, owner: owner) }
  let(:doctor)  { create(:doctor, organization: org) }

  # Next Monday at 10:00 — matches the default schedule in the factory
  let(:monday_at_10) do
    today      = Time.current
    days_ahead = 1 - today.wday
    days_ahead += 7 if days_ahead <= 0
    (today + days_ahead.days).change(hour: 10, min: 0, sec: 0)
  end

  before do
    ActsAsTenant.current_tenant = org
    # Give the doctor a Monday schedule
    create(:schedule, organization: org, doctor: doctor, day_of_week: :monday)
  end

  after { ActsAsTenant.current_tenant = nil }

  # --- Validaciones básicas ---
  describe "validaciones" do
    it "es válido con atributos correctos" do
      appt = build(:appointment,
        organization:    org,
        doctor:          doctor,
        owner:           owner,
        patient:         patient,
        scheduled_at:    monday_at_10,
        ends_at:         monday_at_10 + 30.minutes
      )
      expect(appt).to be_valid
    end

    it "requiere reason" do
      appt = build(:appointment, organization: org, doctor: doctor,
                   owner: owner, patient: patient, reason: nil)
      expect(appt).not_to be_valid
      expect(appt.errors[:reason]).to be_present
    end

    it "requiere scheduled_at" do
      appt = build(:appointment, organization: org, doctor: doctor,
                   owner: owner, patient: patient, scheduled_at: nil)
      expect(appt).not_to be_valid
    end
  end

  # --- ends_at debe ser posterior a scheduled_at ---
  describe "ends_at posterior a scheduled_at" do
    it "es inválido cuando ends_at <= scheduled_at" do
      appt = build(:appointment,
        organization: org, doctor: doctor, owner: owner, patient: patient,
        scheduled_at: monday_at_10,
        ends_at:      monday_at_10 - 10.minutes
      )
      expect(appt).not_to be_valid
      expect(appt.errors[:ends_at]).to be_present
    end
  end

  # --- Transiciones de estado ---
  describe "transiciones de estado" do
    let(:appt) { create(:appointment, organization: org, doctor: doctor, owner: owner, patient: patient) }

    it "puede pasar de pending a confirmed" do
      appt.update(status: :confirmed)
      expect(appt.reload).to be_confirmed
    end

    it "no puede pasar de completed a confirmed" do
      appt.update_columns(status: 3) # completed
      appt.status = :confirmed
      expect(appt).not_to be_valid
      expect(appt.errors[:status]).to be_present
    end

    it "no puede pasar de cancelled a confirmed" do
      appt.update_columns(status: 4) # cancelled
      appt.status = :confirmed
      expect(appt).not_to be_valid
    end
  end

  # --- Double booking ---
  describe "sin double booking" do
    let!(:existing) do
      create(:appointment,
        organization: org, doctor: doctor, owner: owner, patient: patient,
        scheduled_at: monday_at_10,
        ends_at:      monday_at_10 + 30.minutes
      )
    end

    it "no permite dos citas del mismo doctor en el mismo horario" do
      owner2   = create(:owner, organization: org)
      patient2 = create(:patient, organization: org, owner: owner2)
      conflict = build(:appointment,
        organization: org, doctor: doctor, owner: owner2, patient: patient2,
        scheduled_at: monday_at_10 + 10.minutes,
        ends_at:      monday_at_10 + 40.minutes
      )
      expect(conflict).not_to be_valid
      expect(conflict.errors[:base]).to include("el doctor ya tiene una cita en ese horario")
    end

    it "sí permite dos citas del mismo doctor en horarios distintos" do
      owner2   = create(:owner, organization: org)
      patient2 = create(:patient, organization: org, owner: owner2)
      non_conflict = build(:appointment,
        organization: org, doctor: doctor, owner: owner2, patient: patient2,
        scheduled_at: monday_at_10 + 1.hour,
        ends_at:      monday_at_10 + 90.minutes
      )
      expect(non_conflict).to be_valid
    end
  end

  # --- Enums ---
  describe "enums" do
    it { should define_enum_for(:status).with_values(pending: 0, confirmed: 1, in_progress: 2, completed: 3, cancelled: 4, no_show: 5) }
    it { should define_enum_for(:appointment_type).with_values(first_visit: 0, follow_up: 1, emergency: 2, routine: 3) }
  end
end
