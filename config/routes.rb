require "sidekiq/web"

Rails.application.routes.draw do
  # ── Health check (sin auth — para load balancers y Docker healthcheck) ──────
  get "/health", to: "health#show"

  # ── Sidekiq Web UI ────────────────────────────────────────────────────────────
  # Rails API mode no incluye sesiones — se las inyectamos solo a Sidekiq::Web
  Sidekiq::Web.use ActionDispatch::Session::CookieStore,
    key:       "_sidekiq_session",
    secret:    Rails.application.secret_key_base,
    same_site: :strict,
    expire_after: 24.hours

  if Rails.env.production?
    Sidekiq::Web.use(Rack::Auth::Basic) do |username, password|
      sidekiq_user = ENV.fetch("SIDEKIQ_WEB_USERNAME", "admin")
      sidekiq_pass = ENV.fetch("SIDEKIQ_WEB_PASSWORD", "")
      ActiveSupport::SecurityUtils.secure_compare(username, sidekiq_user) &
        ActiveSupport::SecurityUtils.secure_compare(password, sidekiq_pass)
    end
  end
  mount Sidekiq::Web => "/panel-jobs"

  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  namespace :api do
    namespace :v1 do
      # Auth
      post   "auth/sign_up",       to: "auth/registrations#create"
      post   "auth/sign_in",       to: "auth/sessions#create"
      delete "auth/sign_out",      to: "auth/sessions#destroy"
      post   "auth/refresh",       to: "auth/sessions#refresh"
      post   "auth/sign_up_staff", to: "auth/registrations#create_staff"
      post   "auth/forgot_password",    to: "auth/passwords#forgot"
      post   "auth/reset_password",     to: "auth/passwords#reset"
      post   "auth/verify_email",       to: "auth/email_verifications#verify"
      post   "auth/resend_verification", to: "auth/email_verifications#resend"

      # Organizations
      resource :organization, only: [ :show, :update ] do
        patch :upload_logo, on: :member
      end

      # Doctors
      resources :doctors, only: [ :index, :show, :create, :update, :destroy ] do
        resources :schedules,       only: [ :index, :create, :update, :destroy ]
        resources :schedule_blocks, only: [ :index, :create, :destroy ]
        member do
          get :availability
          get :weekly_appointments
        end
      end

      # Owners y Patients
      resources :owners, only: [ :index, :show, :create, :update, :destroy ] do
        resources :patients, only: [ :index, :show, :create, :update, :destroy ]
      end

      resources :patients, only: [ :index, :show, :create, :update ] do
        resources :weight_records, only: [ :index, :create, :destroy ]
        get :medical_records, to: "medical_records#patient_records"
      end

      resources :medical_records, only: [ :index, :show, :create, :update ]

      # Appointments
      resources :appointments, only: [ :index, :show, :create, :update ] do
        member do
          patch :confirm
          patch :cancel
          patch :complete
          patch :cancel_series
          patch :start
          patch :no_show
        end
        resources :payments, only: [ :index, :create ]
      end

      # Payments report
      get "payments", to: "payments#index_all"

      # Notifications
      resources :notifications, only: [ :index, :show ] do
        member do
          patch :mark_as_read
        end
        collection do
          patch :mark_all_as_read
        end
      end

      # Perfil de usuario
      get    "me",                    to: "users#me"
      patch  "me",                    to: "users#update_me"
      patch  "me/change_password",    to: "users#change_password"
      resources :users, only: [ :index, :show, :update ] do
        member do
          patch :admin_change_password
        end
      end

      # Dashboards
      get "dashboard/stats",   to: "dashboard#stats"
      get "dashboard/charts",  to: "dashboard#charts"   # Gráficas básicas (todos los planes)
      get "dashboard/alerts",  to: "dashboard#alerts"   # Alertas operacionales (todos los planes)
      get "dashboard/reports", to: "reports#index"      # Reportes avanzados (plan premium)

      # Inventario
      resources :inventory, only: [ :index, :show, :create, :update, :destroy ] do
        resources :movements, controller: "stock_movements", only: [ :index, :create ]
        collection do
          get :alerts
          get :categories
          get :search
        end
      end

      # Waitlist
      resources :waitlist_entries, only: [ :index, :create, :update, :destroy ]

      # Planes — configuración pública de planes para comparación en frontend
      get "plans", to: "plans#index"

      # Estado de pago del mes actual
      get "billing/status", to: "billing_status#show"

      # Lookup (público — para resolución de org por email en login)
      get "lookup", to: "lookup#organization"

      # Search
      get "search", to: "search#index"
    end

    namespace :superadmin do
      get "dashboard/stats", to: "dashboard#stats"
      resources :organizations, only: [ :index, :show ] do
        member do
          patch :update_license
        end
      end
      resources :users, only: [ :index, :create, :update ] do
          member do
            patch :change_password
          end
        end
      resources :plan_configurations, only: [ :index, :update ]
      resources :billing, only: [ :index, :create, :destroy ]
    end
  end
  match "*unmatched", to: "errors#not_found", via: :all,
        constraints: lambda { |req| !req.path.start_with?("/rails/") }
end
