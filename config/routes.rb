Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do

      # Auth
      post   'auth/sign_up',  to: 'auth/registrations#create'
      post   'auth/sign_in',  to: 'auth/sessions#create'
      delete 'auth/sign_out', to: 'auth/sessions#destroy'

      # Organizations
      resource :organization, only: [:show, :update]

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
  match '*unmatched', to: 'application#not_found', via: :all
end