class LocationPolicy < ApplicationPolicy
  def index?  = admin? || receptionist? || doctor?
  def show?   = admin? || receptionist? || doctor?
  def create? = admin?
  def update? = admin?
  def destroy? = admin?
end
