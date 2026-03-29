class AppointmentPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    admin? || receptionist? || doctor?
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

  def complete?
    admin? || receptionist? || doctor?
  end

  def start?
    admin? || receptionist? || doctor?
  end

  def no_show?
    admin? || receptionist? || doctor?
  end

  def cancel_series?
    admin? || receptionist? || doctor?
  end
end
