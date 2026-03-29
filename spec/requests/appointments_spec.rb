require 'rails_helper'

RSpec.describe "Appointments API", type: :request do
  let!(:org)    { create(:organization, :basic) }
  let!(:admin)  { create(:user, organization: org) }
  let!(:doctor) { create(:doctor, organization: org) }
  let!(:owner)  { create(:owner, organization: org) }
  let!(:patient) { create(:patient, organization: org, owner: owner) }

  # Monday at 10:00
  let(:monday_at_10) do
    today      = Time.current
    days_ahead = 1 - today.wday
    days_ahead += 7 if days_ahead <= 0
    (today + days_ahead.days).change(hour: 10, min: 0, sec: 0)
  end

  before do
    ActsAsTenant.current_tenant = org
    create(:schedule, organization: org, doctor: doctor, day_of_week: :monday)
    @token = sign_in_as(admin, org)
  end

  after { ActsAsTenant.current_tenant = nil }

  describe "GET /api/v1/appointments" do
    before do
      create(:appointment, organization: org, doctor: doctor, owner: owner, patient: patient)
    end

    it "retorna lista de citas paginada" do
      get "/api/v1/appointments",
        headers: auth_headers(@token, org)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]).to be_an(Array)
      expect(body["meta"]).to include("current_page", "total_count")
    end

    it "requiere autenticación" do
      get "/api/v1/appointments", headers: json_headers(org)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/appointments" do
    let(:valid_params) do
      {
        appointment: {
          doctor_id:        doctor.id,
          patient_id:       patient.id,
          owner_id:         owner.id,
          scheduled_at:     monday_at_10.iso8601,
          appointment_type: "first_visit",
          reason:           "Consulta general"
        }
      }
    end

    it "crea una cita con datos válidos" do
      expect {
        post "/api/v1/appointments",
          params: valid_params.to_json,
          headers: auth_headers(@token, org)
      }.to change(Appointment, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["data"]["attributes"]["reason"]).to eq("Consulta general")
    end

    it "falla sin motivo (reason)" do
      post "/api/v1/appointments",
        params: valid_params.deep_merge(appointment: { reason: "" }).to_json,
        headers: auth_headers(@token, org)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "detecta conflicto de horario" do
      create(:appointment, organization: org, doctor: doctor, owner: owner, patient: patient,
             scheduled_at: monday_at_10, ends_at: monday_at_10 + 30.minutes)

      post "/api/v1/appointments",
        params: valid_params.to_json,
        headers: auth_headers(@token, org)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/appointments/:id" do
    let!(:appt) do
      create(:appointment, organization: org, doctor: doctor, owner: owner, patient: patient,
             scheduled_at: monday_at_10, ends_at: monday_at_10 + 30.minutes)
    end

    it "actualiza el estado de pending a confirmed" do
      patch "/api/v1/appointments/#{appt.id}",
        params: { appointment: { status: "confirmed" } }.to_json,
        headers: auth_headers(@token, org)

      expect(response).to have_http_status(:ok)
      expect(appt.reload).to be_confirmed
    end

    it "rechaza transición de estado inválida" do
      appt.update_columns(status: 3) # completed
      patch "/api/v1/appointments/#{appt.id}",
        params: { appointment: { status: "confirmed" } }.to_json,
        headers: auth_headers(@token, org)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/v1/appointments/:id" do
    let!(:appt) do
      create(:appointment, organization: org, doctor: doctor, owner: owner, patient: patient)
    end

    it "elimina la cita" do
      expect {
        delete "/api/v1/appointments/#{appt.id}",
          headers: auth_headers(@token, org)
      }.to change(Appointment, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it "retorna 404 para cita de otra organización" do
      other_org  = create(:organization)
      other_appt = create(:appointment, organization: other_org)

      delete "/api/v1/appointments/#{other_appt.id}",
        headers: auth_headers(@token, org)

      expect(response).to have_http_status(:not_found)
    end
  end
end
