class RefreshToken < ApplicationRecord
  belongs_to :user

  # ── Generation ──────────────────────────────────────────────────────────────

  # Returns [raw_token_string, RefreshToken record]
  # raw_token is what gets sent to the client; we only store the digest.
  def self.generate_for(user)
    raw   = SecureRandom.urlsafe_base64(48)
    digest = Digest::SHA256.hexdigest(raw)

    record = create!(
      user:         user,
      token_digest: digest,
      expires_at:   30.days.from_now
    )

    [raw, record]
  end

  # ── Lookup ───────────────────────────────────────────────────────────────────

  def self.find_valid(raw)
    return nil if raw.blank?
    digest = Digest::SHA256.hexdigest(raw)
    token  = find_by(token_digest: digest)
    return nil unless token
    return nil if token.revoked?
    return nil if token.expired?
    token
  end

  # ── Lifecycle ─────────────────────────────────────────────────────────────────

  def revoke!
    update!(revoked_at: Time.current)
  end

  def revoked?
    revoked_at.present?
  end

  def expired?
    expires_at < Time.current
  end
end
