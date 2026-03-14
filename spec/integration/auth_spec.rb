require 'swagger_helper'

RSpec.describe 'Auth API', type: :request do
  path '/api/v1/auth/sign_up' do
    post 'Registro de organización y usuario admin' do
      tags 'Auth'
      consumes 'application/json'
      produces 'application/json'
      security []

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          organization: {
            type: :object,
            properties: {
              name:        { type: :string, example: 'Clínica Patitas' },
              subdomain:   { type: :string, example: 'patitas' },
              email:       { type: :string, example: 'contacto@patitas.com' },
              phone:       { type: :string, example: '55551234' },
              city:        { type: :string, example: 'Guatemala' },
              country:     { type: :string, example: 'Guatemala' },
              timezone:    { type: :string, example: 'America/Guatemala' },
              clinic_type: { type: :string, example: 'veterinary', enum: ['veterinary', 'pediatric', 'general', 'dental'] }
            },
            required: ['name', 'subdomain', 'email', 'clinic_type']
          },
          user: {
            type: :object,
            properties: {
              first_name:            { type: :string, example: 'Carlos' },
              last_name:             { type: :string, example: 'López' },
              email:                 { type: :string, example: 'carlos@patitas.com' },
              phone:                 { type: :string, example: '55559999' },
              password:              { type: :string, example: 'password123' },
              password_confirmation: { type: :string, example: 'password123' }
            },
            required: ['first_name', 'last_name', 'email', 'password', 'password_confirmation']
          }
        }
      }

      response '201', 'Registro exitoso' do
        schema type: :object,
          properties: {
            message:      { type: :string },
            organization: { type: :object },
            user:         { type: :object }
          }
        run_test!
      end

      response '422', 'Error de validación' do
        schema type: :object,
          properties: {
            errors: { type: :array, items: { type: :string } }
          }
        run_test!
      end
    end
  end

  path '/api/v1/auth/sign_in' do
    post 'Iniciar sesión' do
      tags 'Auth'
      consumes 'application/json'
      produces 'application/json'
      security []

      parameter name: 'X-Organization-Slug', in: :header, type: :string, required: true, description: 'Slug de la organización'
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email:    { type: :string, example: 'carlos@patitas.com' },
              password: { type: :string, example: 'password123' }
            },
            required: ['email', 'password']
          }
        }
      }

      response '200', 'Login exitoso' do
        schema type: :object,
          properties: {
            message: { type: :string },
            token:   { type: :string },
            user:    { type: :object }
          }
        run_test!
      end

      response '401', 'Credenciales incorrectas' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }
        run_test!
      end
    end
  end

  path '/api/v1/auth/sign_out' do
    delete 'Cerrar sesión' do
      tags 'Auth'
      consumes 'application/json'
      produces 'application/json'

      parameter name: 'X-Organization-Slug', in: :header, type: :string, required: true
      parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer TOKEN'

      response '200', 'Sesión cerrada' do
        schema type: :object,
          properties: {
            message: { type: :string }
          }
        run_test!
      end
    end
  end
end