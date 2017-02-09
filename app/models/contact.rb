class Contact < ApplicationRecord
  serialize :survey_data, JSON

  belongs_to :clinic1, class_name: Clinic, required: false
  belongs_to :clinic2, class_name: Clinic, required: false
  belongs_to :clinic3, class_name: Clinic, required: false

  def pick_clinics(clinic_filter = {})
    c1, c2, c3 = Clinic.pick(clinic_filter)
    self.clinic1 = c1
    self.clinic2 = c2
    self.clinic3 = c3
    self.save!
  end

  def clinics
    [self.clinic1, self.clinic2, self.clinic3].compact
  end
end
