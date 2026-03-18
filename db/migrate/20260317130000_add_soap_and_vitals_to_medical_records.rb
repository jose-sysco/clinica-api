class AddSoapAndVitalsToMedicalRecords < ActiveRecord::Migration[7.2]
  def change
    add_column :medical_records, :soap_subjective,          :text    # S — síntomas referidos, motivo
    add_column :medical_records, :soap_objective,           :text    # O — examen físico, hallazgos
    add_column :medical_records, :soap_assessment,          :text    # A — diagnóstico / evaluación
    add_column :medical_records, :soap_plan,                :text    # P — plan de tratamiento

    add_column :medical_records, :heart_rate,               :integer          # ppm
    add_column :medical_records, :respiratory_rate,         :integer          # rpm
    add_column :medical_records, :blood_pressure_systolic,  :integer          # mmHg
    add_column :medical_records, :blood_pressure_diastolic, :integer          # mmHg
    add_column :medical_records, :oxygen_saturation,        :decimal, precision: 4, scale: 1  # %
  end
end
