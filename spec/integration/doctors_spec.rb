require 'swagger_helper'

RSpec.describe 'Doctors API', type: :request do
  path '/api/v1/doctors' do
    get 'Lista de doctores' do
      tags 'Doctors'
      produces 'application/json'
      parameter name: 'X-Organization-Slug', in: :header, type: :string, required: true
      parameter name: 'Authorization',        in: :header, type: :string, required: true
      parameter name: :page,     in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response '200', 'Lista de doctores' do
        schema type: :object,
          properties: {
            data:       { type: :array, items: { type: :object } },
            pagination: { type: :object }
          }
        run_test!
      end
    end
  end

  path '/api/v1/doctors/{id}/availability' do
    get 'Disponibilidad del doctor' do
      tags 'Doctors'
      produces 'application/json'
      parameter name: 'X-Organization-Slug', in: :header, type: :string, required: true
      parameter name: 'Authorization',        in: :header, type: :string, required: true
      parameter name: :id,   in: :path,  type: :integer, required: true
      parameter name: :date, in: :query, type: :string,  required: true, description: 'Formato YYYY-MM-DD'

      response '200', 'Slots disponibles' do
        schema type: :object,
          properties: {
            doctor:          { type: :object },
            date:            { type: :string },
            day:             { type: :string },
            slots:           { type: :array, items: { type: :object } },
            total_available: { type: :integer }
          }
        run_test!
      end

      response '400', 'Parámetro date requerido' do
        schema type: :object, properties: { error: { type: :string } }
        run_test!
      end
    end
  end
end