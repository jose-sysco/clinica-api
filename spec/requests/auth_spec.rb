require 'rails_helper'

RSpec.describe "Auth API", type: :request do
  let!(:org)  { create(:organization) }
  let!(:user) { create(:user, organization: org, email: "admin@test.com", password: "Password123!", password_confirmation: "Password123!") }

  describe "POST /api/v1/auth/sign_in" do
    context "con credenciales válidas" do
      it "retorna token y datos del usuario" do
        post "/api/v1/auth/sign_in",
          params: { user: { email: user.email, password: "Password123!" } }.to_json,
          headers: json_headers(org)

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["token"]).to be_present
        expect(body["refresh_token"]).to be_present
        expect(body["user"]["email"]).to eq(user.email)
        expect(body["organization"]["slug"]).to eq(org.slug)
      end
    end

    context "con contraseña incorrecta" do
      it "retorna 401" do
        post "/api/v1/auth/sign_in",
          params: { user: { email: user.email, password: "wrong_password" } }.to_json,
          headers: json_headers(org)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "sin header X-Organization-Slug" do
      it "retorna error" do
        post "/api/v1/auth/sign_in",
          params: { user: { email: user.email, password: "Password123!" } }.to_json,
          headers: { "Content-Type" => "application/json" }

        expect(response).not_to have_http_status(:ok)
      end
    end

    context "con slug de organización incorrecto" do
      it "retorna 401" do
        post "/api/v1/auth/sign_in",
          params: { user: { email: user.email, password: "Password123!" } }.to_json,
          headers: { "Content-Type" => "application/json", "X-Organization-Slug" => "org-que-no-existe" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /api/v1/auth/sign_out" do
    it "cierra la sesión correctamente" do
      token = sign_in_as(user, org)

      delete "/api/v1/auth/sign_out",
        params: { refresh_token: (JSON.parse(response.body)["refresh_token"] rescue "") }.to_json,
        headers: auth_headers(token, org)

      expect(response).to have_http_status(:ok)
    end

    it "retorna 401 sin token" do
      delete "/api/v1/auth/sign_out",
        headers: json_headers(org)

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/lookup" do
    it "retorna el slug de la org dado el email del usuario" do
      get "/api/v1/lookup?email=#{user.email}"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["slug"]).to eq(org.slug)
    end

    it "retorna 404 si el email no existe" do
      get "/api/v1/lookup?email=noexiste@example.com"
      expect(response).to have_http_status(:not_found)
    end
  end
end
