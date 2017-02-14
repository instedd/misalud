class Contact < ApplicationRecord
  serialize :survey_data, JSON

  belongs_to :clinic1, class_name: Clinic, required: false
  belongs_to :clinic2, class_name: Clinic, required: false
  belongs_to :clinic3, class_name: Clinic, required: false

  TRACKING_STATUS = %w(call_started hung_up voice_info sms_info followed_up)
  validates :tracking_status, inclusion: { in: TRACKING_STATUS, message: "\"%{value}\" is not valid" }

  before_save :update_call_started_at, if: -> (contact) {
    contact.tracking_status_changed? && contact.tracking_status == "call_started"
  }
  before_save :ensure_survey_data

  def pick_clinics(clinic_filter = {})
    set_responses(clinic_filter) unless clinic_filter.blank?
    c1, c2, c3 = Clinic.pick(clinic_filter)
    self.clinic1 = c1
    self.clinic2 = c2
    self.clinic3 = c3
    self.save!
    return self.clinics
  end

  def clinics
    [self.clinic1, self.clinic2, self.clinic3].compact
  end

  private

  def set_responses(responses)
    self.language = responses[:lang]
    self.pregnant = responses[:pregnancy]
    self.urgent = responses[:urgent]
    self.known_condition = responses[:known_condition]
    self.borough = responses[:borough]
  end

  def update_call_started_at
    self.call_started_at = Time.now.utc
  end

  def ensure_survey_data
    self.survey_data ||= {}
  end
end
