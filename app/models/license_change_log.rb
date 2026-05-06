class LicenseChangeLog < ApplicationRecord
  belongs_to :organization
  belongs_to :changed_by, class_name: "User", optional: true

  validate :change_data_or_notes_present

  private

  def change_data_or_notes_present
    return if change_data.present? || notes.present?

    errors.add(:base, "Debe haber al menos un cambio o una nota registrada")
  end
end
