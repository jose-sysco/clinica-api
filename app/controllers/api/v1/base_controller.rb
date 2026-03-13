module Api
    module V1
        class BaseController < ApplicationController
            respond_to :json
            
            rescue_from ActiveRecord::RecordNotFound, with: :not_found
            rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
            rescue_from ActsAsTenant::Errors::NoTenantSet, with: :tenant_not_set
            
            private

            def not_found
                render json: { error: e.message}, status: :not_found
            end

            def unprocessable_entity
                render json: { error: e.record.errors.full_messages }, status: :unprocessable_entity
            end

            def tenant_not_set
                render json: { error: "Tenant no configurado" }, status: :bad_request
            end
        
            def paginate(collection)
                collection.page(params[:page]).per(params[:per_page] || 20)
            end
        end
    end
end