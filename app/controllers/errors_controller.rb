class ErrorsController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :set_tenant

    def not_found
        render json: { error: "Ruta no encontrada" }, status: :not_found
    end

    def internal_server_error
        render json: { error: "Error interno del servidor" }, status: :internal_server_error
    end
end
