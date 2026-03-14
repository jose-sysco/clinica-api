class AppointmentPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    admin? || receptionist?
  end

  def update?
    admin? || receptionist?
  end

  def confirm?
    admin? || receptionist? || doctor?
  end

  def cancel?
    admin? || receptionist? || doctor?
  end
end