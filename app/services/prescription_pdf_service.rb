require "prawn"
require "rqrcode"

class PrescriptionPdfService
  PAGE_MARGIN = 36

  def initialize(prescription)
    @prescription = prescription
    @org          = prescription.organization
    @doctor       = prescription.doctor
    @patient      = prescription.patient
  end

  def generate
    Prawn::Document.new(page_size: "A5", margin: PAGE_MARGIN) do |pdf|
      setup_fonts(pdf)
      draw_header(pdf)
      draw_divider(pdf)
      draw_patient_info(pdf)
      draw_rx_section(pdf)
      draw_medications(pdf)
      draw_notes(pdf) if @prescription.notes.present?
      draw_footer(pdf)
    end.render
  end

  private

  # Prawn usa la fuente Helvetica built-in, que solo soporta Windows-1252.
  # Cualquier carácter fuera de ese set (℞, comillas tipográficas, emojis,
  # guiones largos) hace reventar el render. Reemplazamos los comunes por su
  # equivalente ASCII y descartamos el resto para nunca fallar.
  def safe(str)
    s = str.to_s
    s = s.dup.force_encoding("UTF-8") unless s.encoding == Encoding::UTF_8
    s.scrub("")
       .gsub("℞", "Rx")
       .gsub(/[‘’‚‛]/, "'")
       .gsub(/[“”„‟]/, '"')
       .gsub(/[–—−]/, "-")
       .gsub("…", "...")
       .encode("Windows-1252", invalid: :replace, undef: :replace, replace: "")
       .encode("UTF-8")
  end

  def setup_fonts(pdf)
    pdf.font_families.update(
      "Helvetica" => {
        normal: "Helvetica",
        bold:   "Helvetica-Bold",
        italic: "Helvetica-Oblique"
      }
    )
    pdf.font "Helvetica"
  end

  def draw_header(pdf)
    # Clinic name + doctor info on the left
    pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width - 90) do
      pdf.text safe(@org.name), size: 14, style: :bold, color: "1e3a8a"
      pdf.move_down 4
      pdf.text "Dr(a). #{safe(@doctor.full_name)}", size: 11, color: "374151"
      if @doctor.specialty.present?
        pdf.text safe(@doctor.specialty), size: 9, color: "6b7280"
      end
      pdf.move_down 2
      pdf.text "Lic. #{safe(@doctor.license_number)}", size: 9, color: "6b7280" if @doctor.license_number.present?
      if @org.address.present?
        pdf.text safe(@org.address), size: 8, color: "9ca3af"
      end
      if @org.phone.present?
        pdf.text "Tel: #{safe(@org.phone)}", size: 8, color: "9ca3af"
      end
    end

    # QR code on the right
    qr_data = @prescription.public_url
    qr = RQRCode::QRCode.new(qr_data)
    png = qr.as_png(size: 80, border_modules: 1)
    qr_io = StringIO.new(png.to_s)

    pdf.bounding_box([pdf.bounds.width - 85, pdf.bounds.absolute_top - PAGE_MARGIN], width: 80, height: 80) do
      pdf.image qr_io, width: 80, height: 80
      pdf.move_down 2
      pdf.text "Verificar", size: 6, color: "9ca3af", align: :center
    end
  end

  def draw_divider(pdf)
    pdf.move_down 10
    pdf.stroke_color "e5e7eb"
    pdf.stroke_horizontal_rule
    pdf.move_down 10
  end

  def draw_patient_info(pdf)
    issued = @prescription.issued_at.strftime("%d/%m/%Y")
    valid  = @prescription.valid_until&.strftime("%d/%m/%Y")

    pdf.fill_color "f9fafb"
    pdf.fill_and_stroke_rounded_rectangle [0, pdf.cursor], pdf.bounds.width, 42, 4
    pdf.fill_color "000000"
    pdf.stroke_color "e5e7eb"

    pdf.bounding_box([8, pdf.cursor - 6], width: pdf.bounds.width - 16) do
      pdf.font_size 8 do
        pdf.text "<b>Paciente:</b> #{safe(@patient.name)}    <b>Fecha:</b> #{issued}#{valid ? "    <b>Válida hasta:</b> #{valid}" : ""}",
                 inline_format: true, color: "374151"
        pdf.move_down 4
        patient_details = []
        if @patient.birthdate.present?
          age = ((Date.current - @patient.birthdate) / 365.25).floor
          patient_details << "#{age} años"
        end
        gender_map = { "male" => "Masculino", "female" => "Femenino", "unknown" => nil }
        gender_str = gender_map[@patient.gender.to_s]
        patient_details << gender_str if gender_str.present?
        pdf.text patient_details.join("   "), color: "6b7280" if patient_details.any?
      end
    end

    pdf.move_down 18
  end

  def draw_rx_section(pdf)
    pdf.text "Rx", size: 28, style: :bold, color: "1e3a8a"
    if @prescription.diagnosis.present?
      pdf.move_down 2
      pdf.text "Dx: #{safe(@prescription.diagnosis)}", size: 9, color: "374151"
    end
    pdf.move_down 8
  end

  def draw_medications(pdf)
    @prescription.medications.each_with_index do |med, idx|
      name        = safe(med["name"])
      dose        = safe(med["dose"])
      frequency   = safe(med["frequency"])
      duration    = safe(med["duration"])
      instructions = safe(med["instructions"])

      pdf.font_size 10 do
        pdf.text "#{idx + 1}. <b>#{name}</b>#{dose.present? ? " #{dose}" : ""}", inline_format: true, color: "111827"
      end

      details = []
      details << frequency if frequency.present?
      details << "por #{duration}" if duration.present?
      unless details.empty?
        pdf.font_size 9 do
          pdf.text "   #{details.join(" · ")}", color: "4b5563"
        end
      end

      if instructions.present?
        pdf.font_size 8 do
          pdf.text "   #{instructions}", color: "6b7280", style: :italic
        end
      end

      pdf.move_down 8
    end
  end

  def draw_notes(pdf)
    pdf.move_down 4
    pdf.stroke_color "e5e7eb"
    pdf.dash(2, space: 2)
    pdf.stroke_horizontal_rule
    pdf.undash
    pdf.move_down 6
    pdf.font_size 9 do
      pdf.text "<b>Indicaciones:</b> #{safe(@prescription.notes)}", inline_format: true, color: "374151"
    end
  end

  def draw_footer(pdf)
    pdf.move_down 20
    pdf.stroke_color "e5e7eb"
    pdf.stroke_horizontal_rule
    pdf.move_down 6

    token_short = @prescription.verification_token.first(16)
    pdf.font_size 7 do
      pdf.text "Código de verificación: #{token_short}... · Verifica en: #{@prescription.public_url}",
               color: "9ca3af", align: :center
    end
  end
end
