module AuthHelpers
  # Signs in a user and returns the JWT token.
  # The user must have been created with password "Password123!"
  def sign_in_as(user, organization, password: "Password123!")
    post "/api/v1/auth/sign_in",
      params: { user: { email: user.email, password: password } }.to_json,
      headers: json_headers(organization)
    JSON.parse(response.body)["token"]
  end

  # Returns headers for authenticated requests.
  def auth_headers(token, organization)
    {
      "Authorization"        => "Bearer #{token}",
      "X-Organization-Slug"  => organization.slug,
      "Content-Type"         => "application/json"
    }
  end

  # Returns headers without auth (public endpoints).
  def json_headers(organization = nil)
    h = { "Content-Type" => "application/json" }
    h["X-Organization-Slug"] = organization.slug if organization
    h
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
