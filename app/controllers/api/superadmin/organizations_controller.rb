module Api
  module Superadmin
    class OrganizationsController < BaseController
      def index
        ActsAsTenant.without_tenant do
          orgs = Organization.order(created_at: :desc)
          orgs = orgs.where(status: params[:status]) if params[:status].present?
          orgs = orgs.where(plan: params[:plan])     if params[:plan].present?

          if params[:q].present?
            q = "%#{params[:q].downcase}%"
            orgs = orgs.where("LOWER(name) LIKE ? OR LOWER(email) LIKE ? OR slug LIKE ?", q, q, q)
          end

          pagy, orgs = pagy(orgs, limit: 15)

          render json: {
            data:       orgs.map { |o| org_summary_json(o) },
            pagination: pagy_metadata(pagy)
          }
        end
      end

      def show
        ActsAsTenant.without_tenant do
          org = Organization.find(params[:id])
          render json: org_detail_json(org)
        end
      end

      def update_license
        ActsAsTenant.without_tenant do
          org = Organization.find(params[:id])

          updates = {}
          updates[:plan]          = params[:plan]          if params[:plan].present?
          updates[:status]        = params[:status]        if params[:status].present?
          updates[:trial_ends_at] = params[:trial_ends_at] if params[:trial_ends_at].present?

          if params[:status] == "suspended"
            updates[:suspended_at] = Time.current
          elsif params[:status] == "active"
            updates[:suspended_at] = nil
          end

          org.update!(updates)
          render json: org_detail_json(org)
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      private

      def org_summary_json(org)
        {
          id:                   org.id,
          name:                 org.name,
          slug:                 org.slug,
          email:                org.email,
          phone:                org.phone,
          city:                 org.city,
          country:              org.country,
          clinic_type:          org.clinic_type,
          status:               org.status,
          plan:                 org.plan,
          trial_ends_at:        org.trial_ends_at,
          trial_days_remaining: org.trial_days_remaining,
          trial_expired:        org.trial_expired?,
          on_trial:             org.trial?,
          expiring_soon:        org.expiring_soon?,
          suspended_at:         org.suspended_at,
          users_count:          org.users.count,
          doctors_count:        org.doctors.count,
          patients_count:       org.patients.count,
          appointments_count:   org.appointments.count,
          last_appointment_at:  org.appointments.maximum(:created_at),
          created_at:           org.created_at
        }
      end

      def org_detail_json(org)
        org_summary_json(org).merge(
          phone:     org.phone,
          address:   org.address,
          city:      org.city,
          country:   org.country,
          timezone:  org.timezone,
          subdomain: org.subdomain,
          users:     org.users.order(:role, :first_name).map do |u|
            { id: u.id, full_name: u.full_name, email: u.email, role: u.role, status: u.status }
          end
        )
      end
    end
  end
end
