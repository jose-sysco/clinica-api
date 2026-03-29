class UserPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    admin?
  end

  def update?
    admin?
  end

  def admin_change_password?
    admin?
  end

  def create_staff?
    admin?
  end
end
