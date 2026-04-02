class BackfillEmailVerifiedAtForExistingUsers < ActiveRecord::Migration[7.2]
  def up
    # Todos los usuarios creados antes de esta migración se consideran verificados.
    # Su token de verificación se limpia porque ya no lo necesitan.
    User.where(email_verified_at: nil).update_all(
      email_verified_at:        Time.current,
      email_verification_token: nil
    )
  end

  def down
    # No revertible — no podemos saber quién era verificado antes.
  end
end
