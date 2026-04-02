class AddClinicSpecificFieldsToMedicalRecords < ActiveRecord::Migration[7.2]
  def change
    change_table :medical_records do |t|
      # ── Fisioterapia / Rehabilitación ──────────────────────────────────────
      t.integer :pain_scale                        # EVA 0–10
      t.string  :affected_area                     # "Rodilla derecha", "L4-L5"
      t.text    :range_of_motion                   # descripción de ROM articular
      t.text    :functional_assessment             # evaluación funcional
      t.text    :treatment_performed               # tratamiento aplicado en sesión
      t.text    :rehabilitation_plan               # plan de ejercicios / próximas sesiones
      t.text    :evolution_notes                   # evolución respecto a sesión anterior

      # ── Odontología ────────────────────────────────────────────────────────
      t.string  :dental_procedure                  # "Endodoncia", "Extracción", "Limpieza"
      t.string  :dental_affected_teeth             # "16, 26", "Sector superior"
      t.string  :dental_anesthesia                 # tipo de anestesia utilizada

      # ── Psicología ─────────────────────────────────────────────────────────
      t.integer :session_number                    # número de sesión acumulada
      t.integer :mood_scale                        # escala estado de ánimo 1–10
      t.string  :psychotherapy_technique           # "TCC", "ACT", "EMDR", "Gestalt"
      t.text    :session_objectives                # objetivos de la sesión
      t.text    :session_development               # desarrollo / narrativa de la sesión
      t.text    :session_agreements                # acuerdos / tareas para el paciente

      # ── Nutrición ──────────────────────────────────────────────────────────
      t.decimal :goal_weight, precision: 5, scale: 2
      t.text    :dietary_assessment                # evaluación alimentaria
      t.text    :dietary_plan                      # plan nutricional prescrito
      t.text    :food_restrictions                 # alergias, intolerancias, restricciones
      t.string  :physical_activity_level           # "Sedentario", "Moderado", "Activo"

      # ── Veterinaria ────────────────────────────────────────────────────────
      t.string  :coat_condition                    # "Bueno", "Opaco", "Con parásitos"
      t.text    :vaccination_notes                 # vacunas aplicadas / pendientes
      t.text    :deworming_notes                   # desparasitación
    end
  end
end
