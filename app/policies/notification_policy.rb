class NotificationPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    # solo puede ver sus propias notificaciones
    record.user_id == user.id
  end

  def mark_as_read?
    record.user_id == user.id
  end

  def mark_all_as_read?
    true
  end
end
