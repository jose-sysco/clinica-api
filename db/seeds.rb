puts "🌱 Limpiando base de datos..."
JwtDenylist.destroy_all
Notification.destroy_all
Appointment.destroy_all
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
  phone:       "55551234",
  city:        "Guatemala",
  country:     "Guatemala",
  timezone:    "America/Guatemala",
  clinic_type: :veterinary,
  status:      :active
)

pediatria = Organization.create!(
  name:        "Pediatría San José",
  subdomain:   "sanjose",
  email:       "contacto@sanjose.com",
  phone:       "55554321",
  city:        "Guatemala",
  country:     "Guatemala",
  timezone:    "America/Guatemala",
  clinic_type: :pediatric,
  status:      :active
)

puts "👤 Creando usuarios..."

ActsAsTenant.with_tenant(veterinaria) do
  admin_vet = User.create!(
    organization: veterinaria,
    first_name:   "Ana",
    last_name:    "García",
    email:        "admin@patitas.com",
    phone:        "55550001",
    password:     "password123",
    role:         :admin,
    status:       :active
  )

  doctor_vet_user = User.create!(
    organization: veterinaria,
    first_name:   "Roberto",
    last_name:    "Méndez",
    email:        "roberto@patitas.com",
    phone:        "55550002",
    password:     "password123",
    role:         :doctor,
    status:       :active
  )

  doctor_vet = Doctor.create!(
    organization:          veterinaria,
    user:                  doctor_vet_user,
    specialty:             "Medicina General Veterinaria",
    license_number:        "VET-001",
    bio:                   "Especialista en pequeñas especies con 10 años de experiencia.",
    consultation_duration: 30,
    status:                :active
  )

  [1, 2, 3, 4, 5].each do |day|
    Schedule.create!(
      organization: veterinaria,
      doctor:       doctor_vet,
      day_of_week:  day,
      start_time:   Time.new(2000, 1, 1, 8, 0, 0),
      end_time:     Time.new(2000, 1, 1, 17, 0, 0),
      is_active:    true
    )
  end

  User.create!(
    organization: veterinaria,
    first_name:   "María",
    last_name:    "López",
    email:        "recepcion@patitas.com",
    phone:        "55550003",
    password:     "password123",
    role:         :receptionist,
    status:       :active
  )

  owner1 = Owner.create!(
    organization:   veterinaria,
    first_name:     "Juan",
    last_name:      "Pérez",
    email:          "juan@email.com",
    phone:          "55551111",
    identification: "1234567"
  )

  Patient.create!(
    organization: veterinaria,
    owner:        owner1,
    name:         "Firulais",
    patient_type: :animal,
    species:      "Perro",
    breed:        "Labrador",
    gender:       :male,
    birthdate:    3.years.ago,
    weight:       25.5,
    status:       :active
  )

  Patient.create!(
    organization: veterinaria,
    owner:        owner1,
    name:         "Mishi",
    patient_type: :animal,
    species:      "Gato",
    breed:        "Siamés",
    gender:       :female,
    birthdate:    2.years.ago,
    weight:       4.2,
    status:       :active
  )

  owner2 = Owner.create!(
    organization:   veterinaria,
    first_name:     "Laura",
    last_name:      "Ramírez",
    email:          "laura@email.com",
    phone:          "55552222",
    identification: "7654321"
  )

  Patient.create!(
    organization: veterinaria,
    owner:        owner2,
    name:         "Rocky",
    patient_type: :animal,
    species:      "Perro",
    breed:        "Golden Retriever",
    gender:       :male,
    birthdate:    1.year.ago,
    weight:       18.0,
    status:       :active
  )
end

ActsAsTenant.with_tenant(pediatria) do
  User.create!(
    organization: pediatria,
    first_name:   "Carlos",
    last_name:    "López",
    email:        "admin@sanjose.com",
    phone:        "55550010",
    password:     "password123",
    role:         :admin,
    status:       :active
  )

  doctor_ped_user = User.create!(
    organization: pediatria,
    first_name:   "Sofía",
    last_name:    "Herrera",
    email:        "sofia@sanjose.com",
    phone:        "55550011",
    password:     "password123",
    role:         :doctor,
    status:       :active
  )

  doctor_ped = Doctor.create!(
    organization:          pediatria,
    user:                  doctor_ped_user,
    specialty:             "Pediatría General",
    license_number:        "PED-001",
    bio:                   "Pediatra con enfoque en desarrollo infantil.",
    consultation_duration: 45,
    status:                :active
  )

  [1, 2, 3, 4, 5, 6].each do |day|
    Schedule.create!(
      organization: pediatria,
      doctor:       doctor_ped,
      day_of_week:  day,
      start_time:   Time.new(2000, 1, 1, 9, 0, 0),
      end_time:     Time.new(2000, 1, 1, 18, 0, 0),
      is_active:    true
    )
  end

  owner3 = Owner.create!(
    organization:   pediatria,
    first_name:     "Pedro",
    last_name:      "Castro",
    email:          "pedro@email.com",
    phone:          "55553333",
    identification: "9876543"
  )

  Patient.create!(
    organization: pediatria,
    owner:        owner3,
    name:         "Valentina Castro",
    patient_type: :human,
    gender:       :female,
    birthdate:    5.years.ago,
    status:       :active
  )
end

puts ""
puts "✅ Seeds completados:"
puts "   #{Organization.count} organizaciones"
puts "   #{User.count} usuarios"
puts "   #{Doctor.count} doctores"
puts "   #{Schedule.count} horarios"
puts "   #{Owner.count} propietarios"
puts "   #{Patient.count} pacientes"
puts ""
puts "🔑 Credenciales de prueba:"
puts "   Veterinaria → slug: clinica-veterinaria-patitas"
puts "   Admin:       admin@patitas.com / password123"
puts "   Doctor:      roberto@patitas.com / password123"
puts ""
puts "   Pediatría   → slug: pediatria-san-jose"
puts "   Admin:       admin@sanjose.com / password123"
puts "   Doctor:      sofia@sanjose.com / password123"