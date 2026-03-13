Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Auth
      devise_for :users,
        path: 'auth',
        path_names: {
          sign_in:  'sign_in',
          sign_out: 'sign_out',
          registration: 'sign_up'
        },
        controllers: {
          sessions:      'api/v1/auth/sessions',
          registrations: 'api/v1/auth/registrations'
        }

      # Organizations
      resource :organization, only: [:show, :create, :update]

      # Doctors
      resources :doctors, only: [:index, :show, :create, :update, :destroy] do
        resources :schedules,       only: [:index, :create, :update, :destroy]
        resources :schedule_blocks, only: [:index, :create, :destroy]
      end

      # Owners y Patients
      resources :owners, only: [:index, :show, :create, :update, :destroy] do
        resources :patients, only: [:index, :show, :create, :update, :destroy]
      end

      # Appointments
      resources :appointments, only: [:index, :show, :create, :update] do
        member do
          patch :confirm
          patch :cancel
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
    end
  end
end