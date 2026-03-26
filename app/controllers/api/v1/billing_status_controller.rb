module Api
  module V1
    class BillingStatusController < ApplicationController
      def show
        org = ActsAsTenant.current_tenant

        # Trial no paga
        if org.trial?
          render json: { applicable: false }
          return
        end

        period_date = Date.current.beginning_of_month
        paid        = BillingRecord.exists?(organization: org, period: period_date)

        render json: {
          applicable:      true,
          paid:            paid,
          period:          period_date.strftime("%Y-%m"),
          days_remaining:  (Date.current.end_of_month - Date.current).to_i
        }
      end
    end
  end
end
