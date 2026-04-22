class LicenseChangeLog < ApplicationRecord
  belongs_to :organization
  belongs_to :changed_by, class_name: "User", optional: true

  validates :changes, presence: true
end
