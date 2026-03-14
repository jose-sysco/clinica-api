class OwnerPolicy < ApplicationPolicy
  def index?
    admin? || receptionist? || doctor?
  end

  def show?
    admin? || receptionist? || doctor?
  end

  def create?
    admin? || receptionist?
  end

  def update?
    admin? || receptionist?
  end

  def destroy?
    admin?
  end
end