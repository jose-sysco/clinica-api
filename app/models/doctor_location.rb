class DoctorLocation < ApplicationRecord
  belongs_to :doctor
  belongs_to :location
end
