module Api
  module V1
    class SearchController < BaseController
      def index
        q = params[:q].to_s.strip
        return render json: { patients: [], doctors: [], appointments: [] } if q.length < 2

        like = "%#{q.downcase}%"

        patients = Patient.active
                          .includes(:owner)
                          .where("LOWER(patients.name) LIKE ?", like)
                          .limit(5)
                          .map { |p|
                            {
                              id:         p.id,
                              name:       p.name,
                              owner_name: p.owner&.full_name,
                              type:       "patient"
                            }
                          }

        doctors = Doctor.active
                        .joins(:user)
                        .where("LOWER(users.first_name) LIKE ? OR LOWER(users.last_name) LIKE ? OR LOWER(doctors.specialty) LIKE ?", like, like, like)
                        .limit(4)
                        .map { |d|
                          {
                            id:        d.id,
                            name:      d.full_name,
                            specialty: d.specialty,
                            type:      "doctor"
                          }
                        }

        appointments = Appointment.includes(:patient, :doctor)
                                  .joins(:patient)
                                  .where("LOWER(patients.name) LIKE ?", like)
                                  .where.not(status: [ :cancelled, :no_show ])
                                  .order(scheduled_at: :desc)
                                  .limit(4)
                                  .map { |a|
                                    tz = ActsAsTenant.current_tenant.timezone
                                    {
                                      id:           a.id,
                                      patient_name: a.patient.name,
                                      doctor_name:  a.doctor.full_name,
                                      date:         a.scheduled_at.in_time_zone(tz).strftime("%d %b %Y %H:%M"),
                                      status:       a.status,
                                      type:         "appointment"
                                    }
                                  }

        products = if ActsAsTenant.current_tenant.enabled_features.include?("inventory")
                     Product.active
                            .where("LOWER(name) LIKE ? OR LOWER(category) LIKE ? OR LOWER(sku) LIKE ?", like, like, like)
                            .limit(4)
                            .map { |p|
                              {
                                id:            p.id,
                                name:          p.name,
                                category:      p.category,
                                current_stock: p.current_stock.to_f,
                                unit:          p.unit,
                                low_stock:     p.low_stock?,
                                type:          "product"
                              }
                            }
        else
                     []
        end

        render json: { patients: patients, doctors: doctors, appointments: appointments, products: products }
      end
    end
  end
end
