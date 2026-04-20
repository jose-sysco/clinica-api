# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_04_20_192649) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "appointments", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "doctor_id", null: false
    t.integer "patient_id", null: false
    t.integer "owner_id"
    t.datetime "scheduled_at", null: false
    t.datetime "ends_at", null: false
    t.integer "status", default: 0, null: false
    t.integer "appointment_type", default: 0, null: false
    t.text "reason", null: false
    t.text "notes"
    t.integer "cancelled_by"
    t.text "cancellation_reason"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "recurrence_group_id"
    t.integer "recurrence_index"
    t.integer "recurrence_total"
    t.index ["doctor_id", "scheduled_at", "ends_at"], name: "index_appointments_on_doctor_id_and_scheduled_at_and_ends_at"
    t.index ["doctor_id", "status"], name: "index_appointments_on_doctor_id_and_status"
    t.index ["doctor_id"], name: "index_appointments_on_doctor_id"
    t.index ["organization_id", "status"], name: "index_appointments_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_appointments_on_organization_id"
    t.index ["owner_id"], name: "index_appointments_on_owner_id"
    t.index ["patient_id"], name: "index_appointments_on_patient_id"
    t.index ["recurrence_group_id"], name: "index_appointments_on_recurrence_group_id"
  end

  create_table "billing_records", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.date "period", null: false
    t.decimal "amount_paid", precision: 10, scale: 2, null: false
    t.string "currency", default: "GTQ", null: false
    t.text "notes"
    t.bigint "recorded_by_id", null: false
    t.datetime "recorded_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "period"], name: "index_billing_records_on_organization_id_and_period", unique: true
    t.index ["organization_id"], name: "index_billing_records_on_organization_id"
  end

  create_table "doctors", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "user_id", null: false
    t.string "specialty", null: false
    t.string "license_number"
    t.text "bio"
    t.integer "consultation_duration", default: 30, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "inventory_movements", default: false, null: false
    t.decimal "consultation_fee", precision: 10, scale: 2
    t.decimal "card_surcharge_percent", precision: 5, scale: 2
    t.index ["license_number"], name: "index_doctors_on_license_number", unique: true
    t.index ["organization_id"], name: "index_doctors_on_organization_id"
    t.index ["user_id"], name: "index_doctors_on_user_id"
  end

  create_table "jwt_denylist", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.index ["jti"], name: "index_jwt_denylist_on_jti", unique: true
  end

  create_table "medical_records", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "appointment_id", null: false
    t.integer "patient_id", null: false
    t.integer "doctor_id", null: false
    t.decimal "weight", precision: 5, scale: 2
    t.decimal "height", precision: 5, scale: 2
    t.decimal "temperature", precision: 4, scale: 1
    t.text "diagnosis"
    t.text "treatment"
    t.text "medications"
    t.text "notes"
    t.date "next_visit_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "soap_subjective"
    t.text "soap_objective"
    t.text "soap_assessment"
    t.text "soap_plan"
    t.integer "heart_rate"
    t.integer "respiratory_rate"
    t.integer "blood_pressure_systolic"
    t.integer "blood_pressure_diastolic"
    t.decimal "oxygen_saturation", precision: 4, scale: 1
    t.integer "pain_scale"
    t.string "affected_area"
    t.text "range_of_motion"
    t.text "functional_assessment"
    t.text "treatment_performed"
    t.text "rehabilitation_plan"
    t.text "evolution_notes"
    t.string "dental_procedure"
    t.string "dental_affected_teeth"
    t.string "dental_anesthesia"
    t.integer "session_number"
    t.integer "mood_scale"
    t.string "psychotherapy_technique"
    t.text "session_objectives"
    t.text "session_development"
    t.text "session_agreements"
    t.decimal "goal_weight", precision: 5, scale: 2
    t.text "dietary_assessment"
    t.text "dietary_plan"
    t.text "food_restrictions"
    t.string "physical_activity_level"
    t.string "coat_condition"
    t.text "vaccination_notes"
    t.text "deworming_notes"
    t.index ["appointment_id"], name: "index_medical_records_on_appointment_id", unique: true
    t.index ["doctor_id"], name: "index_medical_records_on_doctor_id"
    t.index ["organization_id"], name: "index_medical_records_on_organization_id"
    t.index ["patient_id"], name: "index_medical_records_on_patient_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "user_id", null: false
    t.integer "appointment_id", null: false
    t.integer "notification_type", default: 0, null: false
    t.integer "channel", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "sent_at"
    t.datetime "read_at"
    t.text "message", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_notifications_on_appointment_id"
    t.index ["organization_id"], name: "index_notifications_on_organization_id"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id", "status"], name: "index_notifications_on_user_id_and_status"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "subdomain", null: false
    t.string "email", null: false
    t.string "phone"
    t.string "address"
    t.string "city"
    t.string "country"
    t.string "timezone", default: "America/Guatemala", null: false
    t.string "logo"
    t.integer "clinic_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "plan", default: 0, null: false
    t.datetime "trial_ends_at"
    t.datetime "suspended_at"
    t.string "primary_color"
    t.string "registration_ip"
    t.decimal "locked_price_monthly", precision: 10, scale: 2
    t.decimal "locked_price_monthly_usd", precision: 10, scale: 2
    t.index ["email"], name: "index_organizations_on_email", unique: true
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
    t.index ["subdomain"], name: "index_organizations_on_subdomain", unique: true
  end

  create_table "owners", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "user_id"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email"
    t.string "phone", null: false
    t.string "address"
    t.string "identification"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "email"], name: "index_owners_on_organization_id_and_email", unique: true
    t.index ["organization_id", "identification"], name: "index_owners_on_organization_id_and_identification", unique: true
    t.index ["organization_id"], name: "index_owners_on_organization_id"
    t.index ["user_id"], name: "index_owners_on_user_id"
  end

  create_table "patients", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "owner_id"
    t.string "name", null: false
    t.integer "patient_type", default: 0, null: false
    t.string "species"
    t.string "breed"
    t.integer "gender", default: 0, null: false
    t.date "birthdate"
    t.decimal "weight", precision: 5, scale: 2
    t.text "notes"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "blood_type"
    t.text "allergies"
    t.text "chronic_conditions"
    t.string "microchip_number"
    t.string "reproductive_status"
    t.index ["organization_id", "status"], name: "index_patients_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_patients_on_organization_id"
    t.index ["owner_id"], name: "index_patients_on_owner_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.bigint "appointment_id", null: false
    t.bigint "recorded_by_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.integer "payment_method", default: 0, null: false
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_payments_on_appointment_id"
    t.index ["organization_id", "appointment_id"], name: "index_payments_on_organization_id_and_appointment_id"
    t.index ["organization_id"], name: "index_payments_on_organization_id"
    t.index ["recorded_by_id"], name: "index_payments_on_recorded_by_id"
  end

  create_table "plan_configurations", force: :cascade do |t|
    t.integer "plan", null: false
    t.string "name", null: false
    t.decimal "price_monthly", precision: 10, scale: 2, default: "0.0"
    t.text "features", default: "[]", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_name"
    t.integer "max_doctors", comment: "null = ilimitado"
    t.integer "max_patients", comment: "null = ilimitado"
    t.decimal "price_monthly_usd", precision: 10, scale: 2, default: "0.0"
    t.index ["plan"], name: "index_plan_configurations_on_plan", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name", null: false
    t.string "description"
    t.string "category"
    t.string "unit", default: "unidad", null: false
    t.decimal "current_stock", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "min_stock", precision: 10, scale: 2, default: "0.0", null: false
    t.string "sku"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "active"], name: "index_products_on_organization_id_and_active"
    t.index ["organization_id", "name"], name: "index_products_on_organization_id_and_name"
    t.index ["organization_id"], name: "index_products_on_organization_id"
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_refresh_tokens_on_token_digest", unique: true
    t.index ["user_id", "revoked_at"], name: "index_refresh_tokens_on_user_id_and_revoked_at"
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "schedule_blocks", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "doctor_id", null: false
    t.datetime "start_datetime", null: false
    t.datetime "end_datetime", null: false
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["doctor_id", "start_datetime", "end_datetime"], name: "idx_on_doctor_id_start_datetime_end_datetime_68e6e69f4c"
    t.index ["doctor_id"], name: "index_schedule_blocks_on_doctor_id"
    t.index ["organization_id"], name: "index_schedule_blocks_on_organization_id"
  end

  create_table "schedules", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "doctor_id", null: false
    t.integer "day_of_week", null: false
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["doctor_id", "day_of_week"], name: "index_schedules_on_doctor_id_and_day_of_week", unique: true
    t.index ["doctor_id"], name: "index_schedules_on_doctor_id"
    t.index ["organization_id"], name: "index_schedules_on_organization_id"
  end

  create_table "stock_movements", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "product_id", null: false
    t.bigint "user_id", null: false
    t.bigint "doctor_id"
    t.bigint "medical_record_id"
    t.integer "movement_type", null: false
    t.decimal "quantity", precision: 10, scale: 2, null: false
    t.decimal "stock_before", precision: 10, scale: 2, null: false
    t.decimal "stock_after", precision: 10, scale: 2, null: false
    t.string "lot_number"
    t.date "expiration_date"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["doctor_id"], name: "index_stock_movements_on_doctor_id"
    t.index ["expiration_date"], name: "index_stock_movements_on_expiration_date"
    t.index ["medical_record_id"], name: "index_stock_movements_on_medical_record_id"
    t.index ["movement_type"], name: "index_stock_movements_on_movement_type"
    t.index ["organization_id"], name: "index_stock_movements_on_organization_id"
    t.index ["product_id"], name: "index_stock_movements_on_product_id"
    t.index ["user_id"], name: "index_stock_movements_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "organization_id", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "phone"
    t.integer "role", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.string "avatar"
    t.string "email_verification_token"
    t.datetime "email_verified_at"
    t.string "last_login_ip"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["email_verification_token"], name: "index_users_on_email_verification_token", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "waitlist_entries", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "doctor_id", null: false
    t.integer "patient_id", null: false
    t.integer "owner_id"
    t.date "preferred_date"
    t.text "notes"
    t.integer "status", default: 0, null: false
    t.datetime "notified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "doctor_id", "status"], name: "idx_on_organization_id_doctor_id_status_4e6505335a"
    t.index ["organization_id", "patient_id"], name: "index_waitlist_entries_on_organization_id_and_patient_id"
  end

  create_table "weight_records", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "patient_id", null: false
    t.decimal "weight", precision: 6, scale: 2, null: false
    t.date "recorded_on", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_weight_records_on_organization_id"
    t.index ["patient_id", "recorded_on"], name: "index_weight_records_on_patient_id_and_recorded_on"
    t.index ["patient_id"], name: "index_weight_records_on_patient_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "billing_records", "organizations"
  add_foreign_key "billing_records", "users", column: "recorded_by_id"
  add_foreign_key "payments", "appointments"
  add_foreign_key "payments", "users", column: "recorded_by_id"
  add_foreign_key "products", "organizations"
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "stock_movements", "doctors"
  add_foreign_key "stock_movements", "medical_records"
  add_foreign_key "stock_movements", "organizations"
  add_foreign_key "stock_movements", "products"
  add_foreign_key "stock_movements", "users"
end
