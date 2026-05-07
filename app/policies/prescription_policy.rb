class PrescriptionPolicy < ApplicationPolicy
  def index?
    admin? || receptionist? || doctor?
  end

  def show?
    admin? || receptionist? || doctor?
  end

  def create?
    admin? || doctor?
  end

  def update?
    admin? || doctor?
  end

  def revoke?
    admin? || doctor?
  end

  def download?
    admin? || receptionist? || doctor?
  end
end
