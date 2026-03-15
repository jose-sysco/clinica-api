class MedicalRecordPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    admin? || doctor?
  end

  def update?
    admin? || doctor?
  end
end