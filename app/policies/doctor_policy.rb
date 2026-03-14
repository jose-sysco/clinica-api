class DoctorPolicy < ApplicationPolicy
  def index?
    true # todos pueden ver la lista de doctores
  end

  def show?
    true # todos pueden ver un doctor
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end
end