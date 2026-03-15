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

ActiveRecord::Schema[7.2].define(version: 2026_03_15_180952) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "appointments", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "doctor_id", null: false
    t.integer "patient_id", null: false
    t.integer "owner_id", null: false
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
    t.index ["doctor_id", "scheduled_at", "ends_at"], name: "index_appointments_on_doctor_id_and_scheduled_at_and_ends_at"
    t.index ["doctor_id", "status"], name: "index_appointments_on_doctor_id_and_status"
    t.index ["doctor_id"], name: "index_appointments_on_doctor_id"
    t.index ["organization_id", "status"], name: "index_appointments_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_appointments_on_organization_id"
    t.index ["owner_id"], name: "index_appointments_on_owner_id"
    t.index ["patient_id"], name: "index_appointments_on_patient_id"
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
    t.string "timezone", default: "UTC", null: false
    t.string "logo"
    t.integer "clinic_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.integer "owner_id", null: false
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
    t.index ["organization_id", "status"], name: "index_patients_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_patients_on_organization_id"
    t.index ["owner_id"], name: "index_patients_on_owner_id"
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
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end
end
