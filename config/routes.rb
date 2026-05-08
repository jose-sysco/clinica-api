Rails.application.routes.draw do
  # ── Health check (sin auth — para load balancers y Docker healthcheck) ──────
  get "/health", to: "health#ping"

  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  namespace :api do
    namespace :v1 do
      # Auth
      post   "auth/sign_up",       to: "auth/registrations#create"
      post   "auth/sign_in",       to: "auth/sessions#create"
      delete "auth/sign_out",      to: "auth/sessions#destroy"
      post   "auth/refresh",       to: "auth/sessions#refresh"
      post   "auth/switch_org",   to: "auth/sessions#switch_org"
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

      resources :medical_records, only: [ :index, :show, :create, :update ] do
        resources :attachments, only: [ :index, :create, :destroy ],
                  controller: "medical_record_attachments"
      end

      # Recetas electrónicas
      resources :prescriptions, only: [ :index, :show, :create, :update ] do
        member do
          patch :revoke
          get   :download
        end
      end

      # Appointments
      resources :appointments, only: [ :index, :show, :create, :update ] do
        member do
          patch :confirm
          patch :cancel
          patch :complete
          patch :cancel_series
          patch :start
          patch :no_show
          get   :admission
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

      # Sedes / ubicaciones
      resources :locations, only: [ :index, :show, :create, :update, :destroy ]

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

      # Push notifications — suscripción del browser
      post   "push_subscriptions", to: "push_subscriptions#create"
      delete "push_subscriptions", to: "push_subscriptions#destroy"
    end

    namespace :public do
      resources :clinics, only: [ :index, :show ], param: :slug do
        member do
          get  :slots
          post :book
        end
      end
      resources :admissions, only: [ :show, :update ], param: :token
      resources :nps,           only: [ :show, :update ], param: :token
      resources :prescriptions, only: [ :show ],         param: :token,
                controller: "prescriptions"
      get "vapid_public_key", to: "vapid#public_key"
    end

    namespace :superadmin do
      get "dashboard/stats", to: "dashboard#stats"
      resources :organizations, only: [ :index, :show, :create ] do
        member do
          patch :update_license
          get   :license_logs
          get   :billing_history
          post  :impersonate
          get   :export_backup
        end
      end
      resources :users, only: [ :index, :create, :update ] do
          member do
            patch :change_password
          end
        end
      resources :plan_configurations, only: [ :index, :update ]
      resources :billing, only: [ :index, :create, :destroy ]
      resources :salespersons, only: [ :index, :create, :update, :destroy ] do
        resources :payments, only: [ :index, :create, :update, :destroy ],
                  controller: "salesperson_payments" do
          collection { get :preview }
        end
      end
      get "reports/commissions", to: "reports#commissions"
    end
  end
  match "*unmatched", to: "errors#not_found", via: :all,
        constraints: lambda { |req| !req.path.start_with?("/rails/") }
end
