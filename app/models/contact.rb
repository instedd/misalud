class Contact < ApplicationRecord

  belongs_to :clinic1, class_name: Clinic, required: false
  belongs_to :clinic2, class_name: Clinic, required: false
  belongs_to :clinic3, class_name: Clinic, required: false

  belongs_to :survey_chosen_clinic, class_name: Clinic, required: false

  TRACKING_STATUS = %w(call_started hung_up voice_info sms_info followed_up)
  validates :tracking_status, inclusion: { in: TRACKING_STATUS, message: "\"%{value}\" is not valid" }

  before_save :update_call_started_at, if: -> (contact) {
    contact.tracking_status_changed? && contact.tracking_status == "call_started"
  }

  def self.find_or_initialize_by_phone(phone)
    Contact.find_or_initialize_by(phone: SmsChannel.clean_phone(phone))
  end

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

  def clinic(index)
    case index.to_i
    when 1 then clinic1
    when 2 then clinic2
    when 3 then clinic3
    end
  end

  def clear_survey_data
    self.survey_was_seen = nil
    self.survey_chosen_clinic_id = nil
    self.survey_clinic_rating = nil
    self.survey_can_be_called = nil
    self.survey_reason_not_seen = nil
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
end
