# Clínica API — Backend

API REST SaaS multitenant para gestión de clínicas. Construida con **Rails 7.2 en modo API**.

---

## Stack

| Capa | Tecnología |
|------|-----------|
| Framework | Rails 7.2 (API mode) |
| Base de datos | PostgreSQL |
| Servidor | Puma |
| Auth | Devise + devise-jwt (JWT en cookies/headers) |
| Multitenancy | acts_as_tenant (por `organization_id`) |
| Autorización | Pundit (policies por recurso) |
| Jobs | Sidekiq + Redis |
| Archivos | ActiveStorage (disco local en dev, S3 en prod) |
| Paginación | Pagy (~9.0) |
| CORS | rack-cors |
| Rate limiting | rack-attack |
| Docs API | rswag (Swagger UI en `/api-docs`) |

---

## Arquitectura multitenant

Cada organización (clínica) es un tenant aislado. El tenant se resuelve por el header `X-Organization-Slug` en cada request.

```
ApplicationController
  before_action :authenticate_user!   # valida JWT + org
  before_action :set_tenant           # ActsAsTenant.current_tenant = org
```

Todos los modelos principales declaran `acts_as_tenant :organization`, lo que scopa automáticamente todas las queries al tenant activo.

---

## Modelos principales

| Modelo | Descripción |
|--------|-------------|
| `Organization` | Clínica/tenant. Tiene plan, trial, features, logo (ActiveStorage) |
| `User` | Usuario del sistema. Roles: `admin`, `doctor`, `receptionist`, `patient`, `superadmin` |
| `Doctor` | Perfil médico ligado a un User. Tiene specialty, schedules, schedule_blocks |
| `Schedule` | Horario semanal del doctor (day_of_week, start_time, end_time) |
| `ScheduleBlock` | Bloqueos de agenda del doctor (vacaciones, etc.) |
| `Patient` | Paciente. Tiene weight_records |
| `Owner` | Dueño del paciente (veterinaria/pediatría) |
| `Appointment` | Cita médica. Estados: pending → confirmed → in_progress → completed / cancelled / no_show |
| `MedicalRecord` | Expediente clínico ligado a una cita |
| `Notification` | Notificación de sistema ligada a una cita y un usuario |
| `WaitlistEntry` | Entrada en la lista de espera |
| `PlanConfiguration` | Features habilitadas por plan (configurable por superadmin) |
| `JwtDenylist` | Tokens JWT revocados (logout) |
| `RefreshToken` | Tokens de refresh para renovación silenciosa |

---

## Planes y features

Los features se almacenan en `PlanConfiguration` y se consultan con `organization.enabled_features`.

| Feature | Trial | Basic | Professional | Enterprise |
|---------|:-----:|:-----:|:------------:|:----------:|
| `appointments` | ✅ | ✅ | ✅ | ✅ |
| `medical_records` | ✅ | ✅ | ✅ | ✅ |
| `notifications` | ✅ | ✅ | ✅ | ✅ |
| `reports` | ❌ | ✅ | ✅ | ✅ |
| `multi_doctor` | ❌ | ❌ | ✅ | ✅ |
| `whatsapp_notifications` | ❌ | ❌ | ✅ | ✅ |
| `inventory` | ❌ | ❌ | ❌ | ✅ |
| `custom_branding` | ❌ | ❌ | ❌ | ✅ |

El límite de doctores se valida en el modelo `Doctor` (validación `on: :create`): sin `multi_doctor` solo se permite 1 doctor activo.

---

## Rutas principales (`/api/v1/`)

```
POST   auth/sign_up              # Registro de nueva org + admin
POST   auth/sign_in              # Login
DELETE auth/sign_out             # Logout
POST   auth/refresh              # Refresh de token
POST   auth/sign_up_staff        # Crear usuario staff (admin)
POST   auth/forgot_password
POST   auth/reset_password

GET    lookup?email=             # Público: resuelve org slug por email (login step 1)

GET    me                        # Perfil del usuario actual (incluye org + logo_url)
PATCH  me                        # Actualizar perfil
PATCH  me/change_password

GET/PATCH/DELETE  organization              # Datos de la org
PATCH             organization/upload_logo  # Subir logo (ActiveStorage)

resources :users               # CRUD de usuarios (solo admin via Pundit)
resources :doctors             # Con: schedules, schedule_blocks, availability, weekly_appointments
resources :patients            # Con: weight_records, medical_records
resources :owners              # Con: patients anidados
resources :appointments        # Con: confirm, cancel, complete, start, no_show, cancel_series
resources :medical_records
resources :notifications       # Con: mark_as_read, mark_all_as_read
resources :waitlist_entries

GET    dashboard/stats          # KPIs del dashboard
GET    dashboard/reports        # Reportes (requiere feature "reports")
GET    search                   # Búsqueda global
```

### Superadmin (`/api/superadmin/`)
```
GET    dashboard/stats
resources :organizations        # Con: update_license
resources :users
resources :plan_configurations  # Editar features por plan
```

---

## Jobs (Sidekiq)

| Job | Trigger | Descripción |
|-----|---------|-------------|
| `AppointmentConfirmationJob` | `after_create_commit` + status → confirmed | Envía confirmación |
| `AppointmentCancellationJob` | status → cancelled | Envía aviso de cancelación |
| `AppointmentReminderJob` | Schedulado | Recordatorios antes de la cita |
| `WaitlistNotificationJob` | Cita cancelada | Notifica a pacientes en espera |

---

## Autorización (Pundit)

Cada recurso tiene su policy en `app/policies/`. Roles definidos en `ApplicationPolicy`:

| Acción | Admin | Doctor | Recepcionista |
|--------|:-----:|:------:|:-------------:|
| Ver citas / doctores / pacientes | ✅ | ✅ | ✅ |
| Crear/cancelar/confirmar citas | ✅ | ✅ | ✅ |
| Crear/editar expedientes | ✅ | ✅ | ❌ |
| Crear pacientes / dueños | ✅ | ✅ (ver) | ✅ |
| Gestionar doctores | ✅ | ❌ | ❌ |
| Gestionar usuarios | ✅ | ❌ | ❌ |
| Configurar organización | ✅ | ❌ | ❌ |

---

## Convenciones importantes

- **Todo SQL raw** en `.order()`, `.group()`, `.pluck()` debe envolverse en `Arel.sql()` (Rails 7.2 strict mode).
- **`ActsAsTenant.without_tenant { ... }`** para queries cross-tenant (ej. lookup por email en login, PlanConfiguration).
- El email de la organización es **inmutable** — no está en `organization_params` del controller.
- `rails_blob_url(org.logo_file, host: request.base_url)` para generar URLs de ActiveStorage.
- La ruta catch-all `match '*unmatched'` excluye `/rails/` para no interceptar rutas de ActiveStorage.
- Usar `reorder()` en lugar de `order()` cuando se quiere sobreescribir el orden de un scope previo.

---

## Variables de entorno

```env
DATABASE_URL=postgresql://...
DEVISE_JWT_SECRET_KEY=...
REDIS_URL=redis://localhost:6379
RAILS_MASTER_KEY=...
```

---

## Comandos

```bash
bundle install
rails db:create db:migrate db:seed
rails s -p 3010          # http://localhost:3010
bundle exec sidekiq      # Worker de jobs
```
