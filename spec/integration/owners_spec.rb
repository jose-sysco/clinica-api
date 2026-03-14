require 'swagger_helper'

RSpec.describe 'Owners API', type: :request do
  path '/api/v1/owners' do
    get 'Lista de propietarios' do
      tags 'Owners'
      produces 'application/json'
      parameter name: 'X-Organization-Slug', in: :header, type: :string, required: true
      parameter name: 'Authorization',        in: :header, type: :string, required: true
      parameter name: :page,     in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false
      parameter name: :q,        in: :query, type: :string,  required: false, description: 'Búsqueda por nombre, email o teléfono'

      response '200', 'Lista de propietarios' do
        schema type: :object,
          properties: {
            data:       { type: :array, items: { type: :object } },
            pagination: { type: :object }
          }
        run_test!
      end
    end

    post 'Crear propietario' do
      tags 'Owners'
      consumes 'application/json'
      produces 'application/json'
      parameter name: 'X-Organization-Slug', in: :header, type: :string, required: true
      parameter name: 'Authorization',        in: :header, type: :string, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          owner: {
            type: :object,
            properties: {
              first_name:     { type: :string,  example: 'Juan' },
              last_name:      { type: :string,  example: 'Pérez' },
              email:          { type: :string,  example: 'juan@email.com' },
              phone:          { type: :string,  example: '55551111' },
              address:        { type: :string,  example: 'Zona 10, Guatemala' },
              identification: { type: :string,  example: '1234567' }
            },
            required: ['first_name', 'last_name', 'phone']
          }
        }
      }

      response '201', 'Propietario creado' do
        run_test!
      end

      response '422', 'Error de validación' do
        schema type: :object, properties: { errors: { type: :array, items: { type: :string } } }
        run_test!
      end
    end
  end

  path '/api/v1/owners/{id}/patients' do
    get 'Lista de pacientes del propietario' do
      tags 'Patients'
      produces 'application/json'
      parameter name: 'X-Organization-Slug', in: :header, type: :string, required: true
      parameter name: 'Authorization',        in: :header, type: :string, required: true
      parameter name: :id,       in: :path,  type: :integer, required: true
      parameter name: :page,     in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response '200', 'Lista de pacientes' do
        schema type: :object,
          properties: {
            data:       { type: :array, items: { type: :object } },
            pagination: { type: :object }
          }
        run_test!
      end
    end

    post 'Crear paciente' do
      tags 'Patients'
      consumes 'application/json'
      produces 'application/json'
      parameter name: 'X-Organization-Slug', in: :header, type: :string, required: true
      parameter name: 'Authorization',        in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          patient: {
            type: :object,
            properties: {
              name:         { type: :string,  example: 'Firulais' },
              patient_type: { type: :string,  example: 'animal', enum: ['human', 'animal'] },
              species:      { type: :string,  example: 'Perro' },
              breed:        { type: :string,  example: 'Labrador' },
              gender:       { type: :string,  example: 'male', enum: ['unknown', 'male', 'female'] },
              birthdate:    { type: :string,  example: '2020-01-01' },
              weight:       { type: :number,  example: 25.5 },
              notes:        { type: :string,  example: 'Alérgico a la penicilina' }
            },
            required: ['name', 'patient_type', 'gender']
          }
        }
      }

      response '201', 'Paciente creado' do
        run_test!
      end

      response '422', 'Error de validación' do
        schema type: :object, properties: { errors: { type: :array, items: { type: :string } } }
        run_test!
      end
    end
  end
end