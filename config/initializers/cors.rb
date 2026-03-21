# Be sure to restart your server when you modify this file.

# En desarrollo se permiten todos los orígenes.
# En producción se restringe al dominio del frontend via FRONTEND_URL.

allowed_origins = if Rails.env.production?
  frontend = ENV.fetch("FRONTEND_URL", nil)
  frontend ? [frontend] : []
else
  ["*"]
end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    resource "*",
      headers: :any,
      expose: ["Authorization"],
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
