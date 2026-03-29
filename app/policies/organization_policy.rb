class OrganizationPolicy < ApplicationPolicy
  def show?
    true
  end

  def update?
    admin?
  end

  def upload_logo?
    admin?
  end
end
