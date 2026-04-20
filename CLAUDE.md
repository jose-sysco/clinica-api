# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Infraestructura de Producción

| Servicio | Plataforma | Plan | URL |
|---|---|---|---|
| **Frontend** (Next.js) | Vercel | Hobby (free) | `agendia.sysco.com.gt` |
| **API** (Rails) | Render | Free (750h/mes) | `api-agendia.sysco.com.gt` |
| **Base de datos** (PostgreSQL) | Supabase | Free | `jzxymuminlzbmpbyczqz.supabase.co` |
| **Redis / Sidekiq** | Upstash | Free Tier (500k cmds/mes) | `apparent-molly-68087.upstash.io` |
| **Uptime monitoring** | UptimeRobot | Free | Apuntar a `GET /ping` (no a `/health`) |

## Commands

```bash
# Development
rails s -p 3010              # Start API server
bundle exec sidekiq          # Start background job worker

# Database
rails db:create db:migrate db:seed
rails db:reset               # Full reset with seed data

# Testing
bundle exec rspec                              # Run all tests
bundle exec rspec spec/models/                 # Model specs only
bundle exec rspec spec/requests/               # Request (behavioral) specs only
bundle exec rspec spec/models/product_spec.rb  # Single file
bundle exec rspec --tag ~pending               # Skip pending specs

# Linting & Security
bin/rubocop -f github        # Lint (style)
bin/brakeman --no-pager      # Security scan

# Docker (full stack)
docker compose up            # Start API + PostgreSQL + Redis + Sidekiq
```

## Database Schema

**Regla:** Antes de responder cualquier pregunta sobre tablas, columnas, tipos de datos, índices o relaciones, leer `db/schema.rb`. No asumir la estructura — verificarla ahí directamente.

## Architecture Overview

**Rails 7.2 API-only** — Multi-tenant SaaS backend for clinic management. The API serves a Next.js frontend.

**Key patterns:**
- Multi-tenancy: `acts_as_tenant :organization` on all models, scoped via `X-Organization-Slug` header
- Authentication: Devise + devise-jwt (Bearer tokens); revoked tokens stored in `jwt_denylist`
- Authorization: Pundit policies in `app/policies/`
- Background jobs: Sidekiq + Redis in `app/jobs/`
- Business logic: service objects in `app/services/`
- Serialization: `jsonapi-serializer` in `app/serializers/`
- Pagination: Pagy

**API versioning:** All routes under `/api/v1/` (controllers in `app/controllers/api/v1/`). Superadmin routes under `/api/superadmin/`.

## Request Lifecycle

1. `ApplicationController` authenticates via JWT, validates `X-Organization-Slug` header, sets tenant with `acts_as_tenant`, and sets `Time.zone` from the organization's timezone.
2. Pundit policies enforce role-based access (`admin`, `doctor`, `receptionist`, `patient`, `superadmin`).
3. Suspended organizations (`org.suspended_at`) and trial-expired tenants (blocks writes, allows reads) are gated in `ApplicationController`.

## Multi-tenancy Rules

- All queries are auto-scoped by `organization_id` via `acts_as_tenant`.
- Cross-tenant operations (e.g., login lookup, plan configs) must wrap: `ActsAsTenant.without_tenant { ... }`.
- Organization email is immutable — never include it in `organization_params`.

## Plans & Feature Flags

Plans: `trial` → `basic` → `professional` → `enterprise`. Features controlled by `PlanConfiguration` records.

| Feature | Trial | Basic | Professional | Enterprise |
|---------|:-----:|:-----:|:------------:|:----------:|
| reports | ❌ | ✅ | ✅ | ✅ |
| multi_doctor | ❌ | ❌ | ✅ | ✅ |
| inventory | ❌ | ❌ | ❌ | ✅ |
| custom_branding | ❌ | ❌ | ❌ | ✅ |

Trial lasts 15 days (`organization.trial_ends_at`).

## Key Models

- **Organization** — Tenant. Has `plan`, `trial_ends_at`, `suspended_at`, `timezone`.
- **User** — Auth entity with roles. Belongs to organization.
- **Doctor** — Extends user; has `consultation_duration` (default 30 min), `schedules` (weekly hours), `schedule_blocks` (blocked times), `inventory_movements` (boolean — enables stock deduction on consultations).
- **Appointment** — Links doctor + patient. Status machine: `pending → confirmed → in_progress → completed / cancelled / no_show`. Validates: no double-booking, within schedule, doctor not blocked. API response includes `doctor.inventory_movements`.
- **MedicalRecord** — SOAP notes + vitals. Linked to appointment. Accepts `used_products` array (`[{ product_id, quantity }]`); if `doctor.inventory_movements` is true, creates StockMovement records of type `:exit`.
- **Patient** — Supports `human` and `animal` patient types (veterinary support).
- **Product** — Inventory item (Enterprise only). Has `name`, `category`, `sku`, `current_stock`, `min_stock`, `unit`, `active`. `low_stock?` returns true when `current_stock <= min_stock`. Scoped by tenant.
- **StockMovement** — Records each inventory change. `movement_type`: `:entry` (purchase/restock) or `:exit` (used in consultation). Stores `stock_before`, `stock_after`, `lot_number`, `expiration_date`, `notes`, `doctor_id`, `medical_record_id`, `user_id`.

## Appointment Scheduling

`DoctorAvailabilityService` generates available time slots:
- Respects doctor's `schedules` (weekly availability by `day_of_week`)
- Excludes `schedule_blocks` and existing appointments
- Uses org timezone (`Time.zone` is set per-request)

## Background Jobs

All triggered by appointment status changes:
- `AppointmentConfirmationJob` — on create/confirm
- `AppointmentCancellationJob` — on cancel
- `AppointmentReminderJob` — 24h before appointment
- `WaitlistNotificationJob` — when slot opens up

## Frontend Integration (Next.js)

### Headers requeridos en cada request
```
Authorization: Bearer <access_token>
X-Organization-Slug: <org_slug>
Content-Type: application/json
```

### Flujo de autenticación
1. `GET /api/v1/lookup?email=` → obtiene el `slug` de la organización
2. `POST /api/v1/auth/sign_in` con header `X-Organization-Slug` → devuelve `token` + `refresh_token` + `user` + `organization`
3. Todas las requests siguientes usan `Authorization: Bearer <token>`
4. Access token expira en **1 hora** — usar `POST /api/v1/auth/refresh` con `refresh_token` para rotar
5. `DELETE /api/v1/auth/sign_out` requiere enviar `refresh_token` en el body para revocar ambos tokens

### Respuesta de login — campos clave
```json
{
  "token": "...",
  "refresh_token": "...",
  "user": { "id", "email", "full_name", "role", "status" },
  "organization": {
    "slug", "plan", "features", "on_trial",
    "trial_expired", "trial_days_remaining", "status"
  }
}
```

### Códigos de error que el frontend debe manejar
| HTTP | `code` en body | Acción en frontend |
|------|---------------|-------------------|
| 401 | — | Redirigir a login |
| 401 | `refresh_expired` | Sesión expirada, logout |
| 402 | `license_suspended` | Mostrar pantalla de licencia suspendida |
| 402 | `trial_expired` | Solo lectura — bloquear acciones de escritura en UI |
| 403 | — | El rol no tiene permiso |

### Paginación (Pagy)
Los endpoints de lista devuelven:
```json
{
  "data": [...],
  "meta": { "current_page", "total_pages", "total_count", "per_page" }
}
```
Parámetros: `?page=1&per_page=20`

### CORS
- Desarrollo: todos los orígenes permitidos (`*`)
- Producción: solo el dominio en `FRONTEND_URL`
- Header expuesto: `Authorization`

### Endpoints públicos (sin auth ni slug)
- `GET /health`
- `GET /api/v1/lookup?email=`

### Base URL
```
http://localhost:3010/api/v1/    # desarrollo
```

## Inventory Module

Routes nested under `/api/v1/inventory` and `/api/v1/inventory/:inventory_id/movements`:
- `GET    /api/v1/inventory` — paginated product list
- `POST   /api/v1/inventory` — create product
- `GET    /api/v1/inventory/:id` — product detail
- `PATCH  /api/v1/inventory/:id` — update product
- `DELETE /api/v1/inventory/:id` — soft-delete (sets `active: false`)
- `GET    /api/v1/inventory/:inventory_id/movements` — stock movement history
- `POST   /api/v1/inventory/:inventory_id/movements` — manual stock movement

**Multi-tenancy note:** Always use `ActsAsTenant.current_tenant` (not `current_organization`) when setting the organization on new records in controllers.

**Global search** — `GET /api/v1/search?q=` returns a `products` array only when `ActsAsTenant.current_tenant.enabled_features.include?("inventory")`. Otherwise returns `[]`.

## Behavior Rules

- Never modify existing migrations — always create a new migration to maintain data integrity.
- Every endpoint or modification must be scoped under `X-Organization-Slug` multi-tenancy — unless I explicitly indicate otherwise.

## SQL Conventions

Raw SQL in `.order()`, `.group()`, `.pluck()` must use `Arel.sql()` to avoid deprecation warnings.

## Environment Variables

Key env vars (see `.env.example` for full list):

```
DATABASE_URL                 # PostgreSQL connection
DEVISE_JWT_SECRET_KEY        # Generate with: rails secret
REDIS_URL                    # Redis connection (Sidekiq)
FRONTEND_URL                 # CORS allowed origin (Next.js)
AWS_ACCESS_KEY_ID / SECRET   # S3 for ActiveStorage (prod)
SIDEKIQ_WEB_USERNAME/PASSWORD # Sidekiq UI auth (prod)
SMTP_*                       # Email delivery
```

## API Documentation

Swagger UI available at `/api-docs` (rswag). Spec files in `swagger/`.

## Testing

Stack: RSpec + FactoryBot + Faker + Shoulda Matchers + SimpleCov

| Carpeta | Tipo |
|---------|------|
| `spec/models/` | Model specs (validaciones, asociaciones, enums, lógica de negocio) |
| `spec/requests/` | Request specs (endpoints reales, auth, RBAC, paginación) |
| `spec/integration/` | Swagger specs (rswag — generan documentación API) |
| `spec/factories/` | Factories con Faker + traits por plan/estado |
| `spec/support/` | Helpers: `auth_helpers.rb` (`sign_in_as`, `auth_headers`), FactoryBot, Shoulda Matchers |

**Patrón para request specs:**
```ruby
let!(:org)   { create(:organization, :basic) }
let!(:admin) { create(:user, organization: org) }
before { @token = sign_in_as(admin, org) }
# luego usar auth_headers(@token, org) en cada request
```

**Patrón para model specs con tenant:**
```ruby
before { ActsAsTenant.current_tenant = org }
after  { ActsAsTenant.current_tenant = nil }
```

- CI runs: Brakeman → Rubocop → RSpec (GitHub Actions at `.github/workflows/ci.yml`)
