class PaymentPolicy < ApplicationPolicy
  def index?   = true
  def create?  = admin? || receptionist? || doctor?
  def index_all? = true
end
