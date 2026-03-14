require 'swagger_helper'

RSpec.describe 'Appointments API', type: :request do
  path '/api/v1/appointments' do
    get 'Lista de citas' do
      tags 'Appointments'
      produces 'application/json'
      parameter name: 'X-Organization-Slug', in: :header, type: :string, required: true
      parameter name: 'Authorization',        in: :header, type: :string, required: true
      parameter name: :page,             in: :query, type: :integer, required: false
      parameter name: :per_page,         in: :query, type: :integer, required: false
      parameter name: :doctor_id,        in: :query, type: :integer, required: false
      parameter name: :patient_id,       in: :query, type: :integer, required: false
      parameter name: :status,           in: :query, type: :string,  required: false, enum: ['pending', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show']
      parameter name: :appointment_type, in: :query, type: :string,  required: false, enum: ['first_visit', 'follow_up', 'emergency', 'routine']
      parameter name: :date,             in: :query, type: :string,  required: false, description: 'Formato YYYY-MM-DD'
      parameter name: :from,             in: :query, type: :string,  required: false, description: 'Formato YYYY-MM-DD'
      parameter name: :to,               in: :query, type: :string,  required: false, description: 'Formato YYYY-MM-DD'
      parameter name: :today,            in: :query, type: :boolean, required: false
      parameter name: :upcoming,         in: :query, type: :boolean, required: false
      parameter name: :past,             in: :query, type: :boolean, required: false

      response '200', 'Lista de citas' do
        schema type: :object,
          properties: {
            data:       { type: :array, items: { type: :object } },
            pagination: { type: :object }
          }
        run_test!
      end
    end

    post 'Crear cita' do
      tags 'Appointments'
      consumes 'application/json'
      produces 'application/json'
      parameter name: 'X-Organization-Slug', in: :header, type: :string, required: true
      parameter name: 'Authorization',        in: :header, type: :string, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          appointment: {
            type: :object,
            properties: {
              doctor_id:        { type: :integer, example: 1 },
              patient_id:       { type: :integer, example: 1 },
              owner_id:         { type: :integer, example: 1 },
              scheduled_at:     { type: :string,  example: '2026-03-16T09:00:00' },
              appointment_type: { type: :string,  example: 'first_visit' },
              reason:           { type: :string,  example: 'Revisión general' }
            },
            required: ['doctor_id', 'patient_id', 'owner_id', 'scheduled_at', 'appointment_type', 'reason']
          }
        }
      }

      response '201', 'Cita creada' do
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

  path '/api/v1/appointments/{id}/confirm' do
    patch 'Confirmar cita' do
      tags 'Appointments'
      parameter name: 'X-Organization-Slug', in: :header, type: :string, required: true
      parameter name: 'Authorization',        in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true

      response '200', 'Cita confirmada' do
        schema type: :object, properties: { message: { type: :string } }
        run_test!
      end
    end
  end

  path '/api/v1/appointments/{id}/cancel' do
    patch 'Cancelar cita' do
      tags 'Appointments'
      consumes 'application/json'
      parameter name: 'X-Organization-Slug', in: :header, type: :string, required: true
      parameter name: 'Authorization',        in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          cancelled_by:        { type: :string, example: 'cancelled_by_patient' },
          cancellation_reason: { type: :string, example: 'No puedo asistir' }
        }
      }

      response '200', 'Cita cancelada' do
        schema type: :object, properties: { message: { type: :string } }
        run_test!
      end
    end
  end
end