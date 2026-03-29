require 'faker'

Faker::Config.locale = 'es'

puts "🌱 Limpiando base de datos..."
JwtDenylist.destroy_all
Notification.destroy_all
Appointment.destroy_all
MedicalRecord.destroy_all
Patient.destroy_all
Owner.destroy_all
Schedule.destroy_all
ScheduleBlock.destroy_all
Doctor.destroy_all
User.destroy_all
Organization.destroy_all

puts "🏥 Creando organizaciones..."

veterinaria = Organization.create!(
  name:        "Clínica Veterinaria Patitas",
  subdomain:   "patitas",
  email:       "contacto@patitas.com",
  phone:       Faker::PhoneNumber.cell_phone,
  city:        "Guatemala",
  country:     "Guatemala",
  timezone:    "America/Guatemala",
  clinic_type: :veterinary,
  status:      :active,
  plan:        :professional
)

pediatria = Organization.create!(
  name:        "Pediatría San José",
  subdomain:   "sanjose",
  email:       "contacto@sanjose.com",
  phone:       Faker::PhoneNumber.cell_phone,
  city:        "Guatemala",
  country:     "Guatemala",
  timezone:    "America/Guatemala",
  clinic_type: :pediatric,
  status:      :active,
  plan:        :professional
)

# ─────────────────────────────────────────────────────
puts "🐾 Poblando Veterinaria Patitas..."
# ─────────────────────────────────────────────────────
ActsAsTenant.with_tenant(veterinaria) do
  User.create!(
    organization: veterinaria, first_name: "Ana", last_name: "García",
    email: "admin@patitas.com", phone: Faker::PhoneNumber.cell_phone,
    password: "password123", role: :admin, status: :active
  )

  User.create!(
    organization: veterinaria, first_name: Faker::Name.first_name, last_name: Faker::Name.last_name,
    email: "recepcion@patitas.com", phone: Faker::PhoneNumber.cell_phone,
    password: "password123", role: :receptionist, status: :active
  )

  vet_specialties = [
    "Medicina General Veterinaria",
    "Cirugía Veterinaria",
    "Dermatología Veterinaria",
    "Cardiología Veterinaria"
  ]

  doctors_vet = vet_specialties.each_with_index.map do |specialty, i|
    u = User.create!(
      organization: veterinaria,
      first_name:   Faker::Name.first_name,
      last_name:    Faker::Name.last_name,
      email:        i == 0 ? "roberto@patitas.com" : Faker::Internet.unique.email,
      phone:        Faker::PhoneNumber.cell_phone,
      password:     "password123",
      role:         :doctor,
      status:       :active
    )

    doc = Doctor.create!(
      organization:          veterinaria,
      user:                  u,
      specialty:             specialty,
      license_number:        "VET-#{Faker::Number.unique.number(digits: 4)}",
      bio:                   Faker::Lorem.sentence(word_count: 12),
      consultation_duration: [ 30, 45 ].sample,
      status:                :active
    )

    [ 1, 2, 3, 4, 5 ].each do |day|
      Schedule.create!(
        organization: veterinaria, doctor: doc, day_of_week: day,
        start_time: Time.new(2000, 1, 1, 8, 0, 0),
        end_time:   Time.new(2000, 1, 1, 17, 0, 0),
        is_active:  true
      )
    end

    doc
  end

  species_breeds = {
    "Perro"  => [ "Labrador", "Golden Retriever", "Husky", "Rottweiler", "Poodle", "Beagle", "Dálmata", "Bulldog" ],
    "Gato"   => [ "Siamés", "Persa", "Maine Coon", "Bengalí", "Angora" ],
    "Pájaro" => [ "Loro", "Canario", "Periquito" ],
    "Conejo" => [ "Holandés", "Angora", "Rex" ]
  }

  pet_names = %w[Firulais Mishi Rocky Luna Coco Nala Thor Bella Max Simba Daisy Toby Rex Cleo Lola Bruno Kira Zeus Canela Pepe]

  all_patients_vet = []

  12.times do
    owner = Owner.create!(
      organization:   veterinaria,
      first_name:     Faker::Name.first_name,
      last_name:      Faker::Name.last_name,
      email:          Faker::Internet.unique.email,
      phone:          Faker::PhoneNumber.cell_phone,
      identification: Faker::IdNumber.unique.spanish_citizen_number
    )

    rand(1..3).times do
      species = species_breeds.keys.sample
      patient = Patient.create!(
        organization: veterinaria,
        owner:        owner,
        name:         pet_names.sample,
        patient_type: :animal,
        species:      species,
        breed:        species_breeds[species].sample,
        gender:       [ :male, :female ].sample,
        birthdate:    Faker::Date.birthday(min_age: 0, max_age: 12),
        weight:       Faker::Number.decimal(l_digits: 1, r_digits: 1).to_f,
        status:       :active
      )
      all_patients_vet << patient
    end
  end

  reasons_vet = [
    "Consulta general", "Vacunación anual", "Control de peso",
    "Revisión post-operatoria", "Desparasitación", "Limpieza dental",
    "Problema de piel", "Revisión de rutina", "Emergencia", "Control de seguimiento"
  ]

  statuses_weighted = [
    :completed, :completed, :completed, :completed,
    :confirmed, :confirmed,
    :pending,
    :cancelled
  ]

  puts "   📅 Generando citas veterinaria..."
  12.times do |months_ago|
    base_date = months_ago.months.ago

    rand(10..20).times do
      appt_date = Faker::Date.between(
        from: base_date.beginning_of_month,
        to:   [ base_date.end_of_month.to_date, Date.today ].min
      )

      doctor  = doctors_vet.sample
      patient = all_patients_vet.sample
      status  = statuses_weighted.sample
      hour    = [ 8, 9, 10, 11, 14, 15, 16 ].sample

      appt = Appointment.new(
        organization:     veterinaria,
        doctor:           doctor,
        patient:          patient,
        owner:            patient.owner,
        scheduled_at:     Time.new(appt_date.year, appt_date.month, appt_date.day, hour, 0, 0),
        ends_at:          Time.new(appt_date.year, appt_date.month, appt_date.day, hour, 30, 0),
        reason:           reasons_vet.sample,
        status:           status,
        appointment_type: :first_visit,
        notes:            status == :completed ? Faker::Lorem.sentence(word_count: 8) : nil
      )
      appt.save(validate: false)
      appt.update_columns(
        created_at: base_date.beginning_of_month + rand(0..25).days,
        updated_at: base_date.beginning_of_month + rand(0..25).days
      )
    end
  end
end

# ─────────────────────────────────────────────────────
puts "👶 Poblando Pediatría San José..."
# ─────────────────────────────────────────────────────
ActsAsTenant.with_tenant(pediatria) do
  User.create!(
    organization: pediatria, first_name: "Carlos", last_name: "López",
    email: "admin@sanjose.com", phone: Faker::PhoneNumber.cell_phone,
    password: "password123", role: :admin, status: :active
  )

  User.create!(
    organization: pediatria, first_name: Faker::Name.first_name, last_name: Faker::Name.last_name,
    email: "recepcion@sanjose.com", phone: Faker::PhoneNumber.cell_phone,
    password: "password123", role: :receptionist, status: :active
  )

  ped_specialties = [
    "Pediatría General",
    "Neonatología",
    "Pediatría del Desarrollo"
  ]

  doctors_ped = ped_specialties.each_with_index.map do |specialty, i|
    u = User.create!(
      organization: pediatria,
      first_name:   Faker::Name.first_name,
      last_name:    Faker::Name.last_name,
      email:        i == 0 ? "sofia@sanjose.com" : Faker::Internet.unique.email,
      phone:        Faker::PhoneNumber.cell_phone,
      password:     "password123",
      role:         :doctor,
      status:       :active
    )

    doc = Doctor.create!(
      organization:          pediatria,
      user:                  u,
      specialty:             specialty,
      license_number:        "PED-#{Faker::Number.unique.number(digits: 4)}",
      bio:                   Faker::Lorem.sentence(word_count: 12),
      consultation_duration: [ 30, 45 ].sample,
      status:                :active
    )

    [ 1, 2, 3, 4, 5, 6 ].each do |day|
      Schedule.create!(
        organization: pediatria, doctor: doc, day_of_week: day,
        start_time: Time.new(2000, 1, 1, 9, 0, 0),
        end_time:   Time.new(2000, 1, 1, 18, 0, 0),
        is_active:  true
      )
    end

    doc
  end

  all_patients_ped = []

  10.times do
    owner = Owner.create!(
      organization:   pediatria,
      first_name:     Faker::Name.first_name,
      last_name:      Faker::Name.last_name,
      email:          Faker::Internet.unique.email,
      phone:          Faker::PhoneNumber.cell_phone,
      identification: Faker::IdNumber.unique.spanish_citizen_number
    )

    rand(1..3).times do
      patient = Patient.create!(
        organization: pediatria,
        owner:        owner,
        name:         "#{Faker::Name.first_name} #{owner.last_name}",
        patient_type: :human,
        gender:       [ :male, :female ].sample,
        birthdate:    Faker::Date.birthday(min_age: 0, max_age: 15),
        status:       :active
      )
      all_patients_ped << patient
    end
  end

  reasons_ped = [
    "Control mensual", "Vacunación", "Fiebre alta", "Control de crecimiento",
    "Revisión general", "Tos persistente", "Infección de oído",
    "Control de peso", "Revisión de desarrollo", "Emergencia pediátrica"
  ]

  statuses_weighted = [
    :completed, :completed, :completed, :completed,
    :confirmed, :confirmed,
    :pending,
    :cancelled
  ]

  puts "   📅 Generando citas pediatría..."
  12.times do |months_ago|
    base_date = months_ago.months.ago

    rand(8..15).times do
      appt_date = Faker::Date.between(
        from: base_date.beginning_of_month,
        to:   [ base_date.end_of_month.to_date, Date.today ].min
      )

      doctor  = doctors_ped.sample
      patient = all_patients_ped.sample
      status  = statuses_weighted.sample
      hour    = [ 9, 10, 11, 14, 15, 16, 17 ].sample

      appt = Appointment.new(
        organization:     pediatria,
        doctor:           doctor,
        patient:          patient,
        owner:            patient.owner,
        scheduled_at:     Time.new(appt_date.year, appt_date.month, appt_date.day, hour, 0, 0),
        ends_at:          Time.new(appt_date.year, appt_date.month, appt_date.day, hour, 45, 0),
        reason:           reasons_ped.sample,
        status:           status,
        appointment_type: :first_visit,
        notes:            status == :completed ? Faker::Lorem.sentence(word_count: 8) : nil
      )
      appt.save(validate: false)
      appt.update_columns(
        created_at: base_date.beginning_of_month + rand(0..25).days,
        updated_at: base_date.beginning_of_month + rand(0..25).days
      )
    end
  end
end

puts ""
puts "✅ Seeds completados:"
puts "   #{Organization.count} organizaciones"
puts "   #{User.count} usuarios totales"
puts "   #{Doctor.count} doctores"
puts "   #{Schedule.count} horarios"
puts "   #{Owner.count} propietarios/tutores"
puts "   #{Patient.count} pacientes"
puts "   #{Appointment.count} citas"
puts ""
puts "🔑 Credenciales:"
puts "   Veterinaria → slug: clinica-veterinaria-patitas"
puts "   Admin:         admin@patitas.com / password123"
puts "   Doctor:        roberto@patitas.com / password123"
puts "   Recepción:     recepcion@patitas.com / password123"
puts ""
puts "   Pediatría   → slug: pediatria-san-jose"
puts "   Admin:         admin@sanjose.com / password123"
puts "   Doctor:        sofia@sanjose.com / password123"
puts "   Recepción:     recepcion@sanjose.com / password123"
