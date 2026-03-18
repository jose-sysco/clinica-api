Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  namespace :api do
    namespace :v1 do

      # Auth
      post   'auth/sign_up',  to: 'auth/registrations#create'
      post   'auth/sign_in',  to: 'auth/sessions#create'
      delete 'auth/sign_out', to: 'auth/sessions#destroy'
      post   'auth/sign_up_staff', to: 'auth/registrations#create_staff'
      post 'auth/forgot_password',  to: 'auth/passwords#forgot'
      post 'auth/reset_password',  to: 'auth/passwords#reset'

      # Organizations
      resource :organization, only: [:show, :update]

      # Doctors
      resources :doctors, only: [:index, :show, :create, :update, :destroy] do
        resources :schedules,       only: [:index, :create, :update, :destroy]
        resources :schedule_blocks, only: [:index, :create, :destroy]
        member do 
          get :availability
          get :weekly_appointments
        end
      end

      # Owners y Patients
      resources :owners, only: [:index, :show, :create, :update, :destroy] do
        resources :patients, only: [:index, :show, :create, :update, :destroy]
      end

      resources :patients, only: [:index, :show, :update] do
        resources :weight_records, only: [:index, :create, :destroy]
        get :medical_records, to: "medical_records#patient_records"
      end

      resources :medical_records, only: [:index, :show, :create, :update]

      # Appointments
      resources :appointments, only: [:index, :show, :create, :update] do
        member do
          patch :confirm
          patch :cancel
          patch :complete
        end
      end

      # Notifications
      resources :notifications, only: [:index, :show] do
        member do
          patch :mark_as_read
        end
        collection do
          patch :mark_all_as_read
        end
      end

      # Perfil de usuario 
      get    'me',                    to: 'users#me'
      patch  'me',                    to: 'users#update_me'
      patch  'me/change_password',    to: 'users#change_password'
      resources :users, only: [:index, :show, :update] do
        member do
          patch :admin_change_password
        end
      end

      # Dashboards
      get 'dashboard/stats', to: 'dashboard#stats'
      get "dashboard/reports", to: "reports#index"

      # Search
      get 'search', to: 'search#index'
    end

    namespace :superadmin do
      get 'dashboard/stats', to: 'dashboard#stats'
      resources :organizations, only: [:index, :show] do
        member do
          patch :update_license
        end
      end
      resources :users, only: [:index, :create, :update]
      resources :plan_configurations, only: [:index, :update]
    end
  end
  match '*unmatched', to: 'errors#not_found', via: :all
end