module Api
  module V1
    class InventoryController < BaseController
      # GET /api/v1/inventory
      def index
        products = Product.active.order(:name)
        products = products.by_name(params[:q])           if params[:q].present?
        products = products.by_category(params[:category]) if params[:category].present?
        products = products.low_stock                      if params[:low_stock] == "true"

        pagy, products = pagy(products, limit: params[:per_page] || 20)

        render json: {
          data:       products.map { |p| product_json(p) },
          pagination: pagy_metadata(pagy)
        }
      end

      # GET /api/v1/inventory/:id
      def show
        product = Product.find(params[:id])
        movements = product.stock_movements.order(created_at: :desc).limit(50)
        render json: product_json(product).merge(movements: movements.map { |m| movement_json(m) })
      end

      # POST /api/v1/inventory
      def create
        product = Product.new(product_params)
        if product.save
          render json: product_json(product), status: :created
        else
          render json: { errors: product.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/inventory/:id
      def update
        product = Product.find(params[:id])
        if product.update(product_params)
          render json: product_json(product)
        else
          render json: { errors: product.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/inventory/:id
      def destroy
        product = Product.find(params[:id])
        product.update!(active: false)
        render json: { message: "Producto desactivado correctamente" }
      end

      # GET /api/v1/inventory/alerts
      def alerts
        low  = Product.active.low_stock.order(:name)
        soon = StockMovement.entry
                            .joins(:product)
                            .where(products: { active: true })
                            .where("stock_movements.expiration_date IS NOT NULL AND stock_movements.expiration_date <= ? AND stock_movements.expiration_date >= ?", 30.days.from_now, Date.today)
                            .order("stock_movements.expiration_date ASC")
                            .includes(:product)

        render json: {
          low_stock:      low.map { |p| { id: p.id, name: p.name, current_stock: p.current_stock, min_stock: p.min_stock, unit: p.unit } },
          expiring_soon:  soon.map { |m| { product_id: m.product_id, product_name: m.product.name, lot_number: m.lot_number, expiration_date: m.expiration_date, unit: m.product.unit } }
        }
      end

      # GET /api/v1/inventory/categories
      def categories
        cats = Product.active.where.not(category: [ nil, "" ]).distinct.pluck(:category).sort
        render json: { data: cats }
      end

      # GET /api/v1/inventory/search — lightweight for medical record autocomplete
      def search
        products = Product.active.by_name(params[:q]).order(:name).limit(10)
        render json: { data: products.map { |p| { id: p.id, name: p.name, unit: p.unit, current_stock: p.current_stock } } }
      end

      private

      def product_params
        params.require(:product).permit(:name, :description, :category, :unit, :min_stock, :sku, :active)
      end

      def product_json(product)
        {
          id:            product.id,
          name:          product.name,
          description:   product.description,
          category:      product.category,
          unit:          product.unit,
          current_stock: product.current_stock,
          min_stock:     product.min_stock,
          sku:           product.sku,
          active:        product.active,
          low_stock:     product.low_stock?,
          created_at:    product.created_at
        }
      end

      def movement_json(m)
        {
          id:             m.id,
          movement_type:  m.movement_type,
          quantity:       m.quantity,
          stock_before:   m.stock_before,
          stock_after:    m.stock_after,
          lot_number:     m.lot_number,
          expiration_date: m.expiration_date,
          notes:          m.notes,
          doctor:         m.doctor ? { id: m.doctor.id, full_name: m.doctor.full_name } : nil,
          user:           { id: m.user_id, full_name: m.user.full_name },
          medical_record_id: m.medical_record_id,
          created_at:     m.created_at
        }
      end
    end
  end
end
