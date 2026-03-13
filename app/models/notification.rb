class Notification < ApplicationRecord
  # Multitenant
  acts_as_tenant :organization

  # Asociaciones
  belongs_to :organization
  belongs_to :user
  belongs_to :appointment

  # Enums
  enum notification_type: {
    confirmation: 0,
    reminder:     1,
    cancellation: 2,
    reschedule:   3
  }

  enum channel: {
    email: 0,
    sms:   1,
    push:  2
  }

  enum status: {
    pending: 0,
    sent:    1,
    failed:  2,
    read:    3
  }

  # Validaciones
  validates :notification_type, presence: true
  validates :channel,           presence: true
  validates :status,            presence: true
  validates :message,           presence: true

  # Callbacks
  before_save :set_sent_at,  if: -> { status_changed? && sent? }
  before_save :set_read_at,  if: -> { status_changed? && read? }

  # Scopes
  scope :unread,   -> { where(read_at: nil) }
  scope :pending,  -> { where(status: :pending) }
  scope :failed,   -> { where(status: :failed) }

  # Helpers
  def mark_as_read!
    update(status: :read)
  end

  def mark_as_sent!
    update(status: :sent)
  end

  private

  def set_sent_at
    self.sent_at = Time.current
  end

  def set_read_at
    self.read_at = Time.current
  end
end