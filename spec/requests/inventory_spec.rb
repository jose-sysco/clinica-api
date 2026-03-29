require 'rails_helper'

RSpec.describe "Inventory API", type: :request do
  # Enterprise plan is required for inventory
  let!(:org)   { create(:organization, :enterprise) }
  let!(:admin) { create(:user, organization: org) }

  before do
    ActsAsTenant.current_tenant = org
    @token = sign_in_as(admin, org)
  end

  after { ActsAsTenant.current_tenant = nil }

  describe "GET /api/v1/inventory" do
    before do
      create_list(:product, 3, organization: org)
      create(:product, :inactive, organization: org)
    end

    it "retorna lista de productos paginada" do
      get "/api/v1/inventory", headers: auth_headers(@token, org)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]).to be_an(Array)
      expect(body["meta"]).to include("total_count")
    end

    it "requiere autenticación" do
      get "/api/v1/inventory", headers: json_headers(org)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/inventory" do
    let(:valid_params) do
      {
        product: {
          name:          "Amoxicilina 500mg",
          category:      "medicamento",
          unit:          "cápsula",
          current_stock: 100,
          min_stock:     20,
          active:        true
        }
      }
    end

    it "crea un producto con datos válidos" do
      expect {
        post "/api/v1/inventory",
          params: valid_params.to_json,
          headers: auth_headers(@token, org)
      }.to change(Product, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["data"]["attributes"]["name"]).to eq("Amoxicilina 500mg")
    end

    it "falla sin nombre" do
      post "/api/v1/inventory",
        params: valid_params.deep_merge(product: { name: "" }).to_json,
        headers: auth_headers(@token, org)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "falla con stock negativo" do
      post "/api/v1/inventory",
        params: valid_params.deep_merge(product: { current_stock: -1 }).to_json,
        headers: auth_headers(@token, org)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/inventory/:id" do
    let!(:product) { create(:product, organization: org) }

    it "retorna el producto" do
      get "/api/v1/inventory/#{product.id}",
        headers: auth_headers(@token, org)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]["id"]).to eq(product.id.to_s)
    end

    it "retorna 404 para producto de otra organización" do
      other_product = create(:product, organization: create(:organization, :enterprise))

      get "/api/v1/inventory/#{other_product.id}",
        headers: auth_headers(@token, org)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/inventory/:id" do
    let!(:product) { create(:product, organization: org) }

    it "actualiza el producto" do
      patch "/api/v1/inventory/#{product.id}",
        params: { product: { name: "Nombre Actualizado" } }.to_json,
        headers: auth_headers(@token, org)

      expect(response).to have_http_status(:ok)
      expect(product.reload.name).to eq("Nombre Actualizado")
    end
  end

  describe "GET /api/v1/inventory/alerts" do
    before do
      create(:product, :low_stock, organization: org)
      create(:product, organization: org) # stock normal
    end

    it "retorna solo productos con stock bajo" do
      get "/api/v1/inventory/alerts",
        headers: auth_headers(@token, org)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].length).to eq(1)
    end
  end

  describe "plan insuficiente" do
    it "bloquea el acceso a organizaciones que no son Enterprise" do
      basic_org   = create(:organization, :basic)
      basic_admin = create(:user, organization: basic_org)
      basic_token = sign_in_as(basic_admin, basic_org)

      get "/api/v1/inventory", headers: auth_headers(basic_token, basic_org)

      expect(response).to have_http_status(:forbidden).or have_http_status(:payment_required)
    end
  end
end
