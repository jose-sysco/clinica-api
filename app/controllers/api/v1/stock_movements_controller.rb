module Api
  module V1
    class StockMovementsController < BaseController
      # GET /api/v1/inventory/:inventory_id/movements
      def index
        product   = Product.find(params[:inventory_id])
        movements = product.stock_movements.includes(:user, :doctor).order(created_at: :desc)
        pagy, movements = pagy(movements, limit: params[:per_page] || 30)

        render json: {
          data:       movements.map { |m| movement_json(m) },
          pagination: pagy_metadata(pagy)
        }
      end

      # POST /api/v1/inventory/:inventory_id/movements
      def create
        product  = Product.find(params[:inventory_id])
        movement = product.stock_movements.new(movement_params)
        movement.organization = ActsAsTenant.current_tenant
        movement.user         = current_user

        if movement.save
          render json: movement_json(movement), status: :created
        else
          render json: { errors: movement.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def movement_params
        params.require(:stock_movement).permit(:movement_type, :quantity, :lot_number, :expiration_date, :notes, :doctor_id)
      end

      def movement_json(m)
        {
          id:              m.id,
          movement_type:   m.movement_type,
          quantity:        m.quantity,
          stock_before:    m.stock_before,
          stock_after:     m.stock_after,
          lot_number:      m.lot_number,
          expiration_date: m.expiration_date,
          notes:           m.notes,
          doctor:          m.doctor ? { id: m.doctor.id, full_name: m.doctor.full_name } : nil,
          user:            { id: m.user_id, full_name: m.user.full_name },
          medical_record_id: m.medical_record_id,
          created_at:      m.created_at
        }
      end
    end
  end
end
