require 'swagger_helper'

RSpec.describe 'Users API', type: :request do
  path '/api/v1/me' do
    get 'Perfil del usuario actual' do
      tags 'Users'
      produces 'application/json'
      parameter name: 'X-Organization-Slug', in: :header, type: :string, required: true
      parameter name: 'Authorization',        in: :header, type: :string, required: true

      response '200', 'Perfil del usuario' do
        schema type: :object,
          properties: {
            id:           { type: :integer },
            email:        { type: :string },
            first_name:   { type: :string },
            last_name:    { type: :string },
            full_name:    { type: :string },
            phone:        { type: :string },
            role:         { type: :string },
            status:       { type: :string },
            avatar:       { type: :string, nullable: true },
            organization: { type: :object },
            created_at:   { type: :string }
          }
        run_test!
      end
    end

    patch 'Actualizar perfil' do
      tags 'Users'
      consumes 'application/json'
      produces 'application/json'
      parameter name: 'X-Organization-Slug', in: :header, type: :string, required: true
      parameter name: 'Authorization',        in: :header, type: :string, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              first_name: { type: :string, example: 'Carlos' },
              last_name:  { type: :string, example: 'López' },
              phone:      { type: :string, example: '55559999' },
              avatar:     { type: :string, example: 'https://...' }
            }
          }
        }
      }

      response '200', 'Perfil actualizado' do
        run_test!
      end
    end
  end

  path '/api/v1/me/change_password' do
    patch 'Cambiar contraseña' do
      tags 'Users'
      consumes 'application/json'
      produces 'application/json'
      parameter name: 'X-Organization-Slug', in: :header, type: :string, required: true
      parameter name: 'Authorization',        in: :header, type: :string, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          current_password:      { type: :string, example: 'password123' },
          password:              { type: :string, example: 'newpassword456' },
          password_confirmation: { type: :string, example: 'newpassword456' }
        },
        required: ['current_password', 'password', 'password_confirmation']
      }

      response '200', 'Contraseña actualizada' do
        schema type: :object, properties: { message: { type: :string } }
        run_test!
      end

      response '422', 'Contraseña incorrecta' do
        schema type: :object, properties: { error: { type: :string } }
        run_test!
      end
    end
  end
end