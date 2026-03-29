class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    admin? || doctor? || receptionist?
  end

  def show?
    admin? || doctor? || receptionist?
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

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.all
    end

    private

    attr_reader :user, :scope
  end

  private

  def admin?
    user.admin?
  end

  def doctor?
    user.doctor?
  end

  def receptionist?
    user.receptionist?
  end

  def patient?
    user.patient?
  end
end
