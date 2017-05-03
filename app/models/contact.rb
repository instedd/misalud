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

  scope :inbound_calls, -> { all }
  scope :hang_ups, -> { where(tracking_status: 'hung_up') }
  scope :voice_info, -> { where(tracking_status: 'voice_info') }
  scope :sms_info, -> { where(tracking_status: 'sms_info') }
  scope :followed_up, -> { where(tracking_status: 'followed_up') }

  scope :surveys_scheduled, -> { where("tracking_status <> 'followed_up' AND survey_status IS NULL AND survey_scheduled_at IS NOT NULL") }
  scope :surveys_ongoing, -> { surveys_ongoing_or_stalled.where("survey_updated_at >= ?", 1.day.ago) }
  scope :surveys_stalled, -> { surveys_ongoing_or_stalled.where("survey_updated_at < ?", 1.day.ago) }
  scope :surveys_ongoing_or_stalled, -> { where("tracking_status <> 'followed_up' AND survey_status IS NOT NULL") }

  scope :survey_ready_to_start, -> {
    t = Time.now.utc
    surveys_scheduled
      .where("survey_scheduled_at <= ?", t)
      .where("(EXTRACT(HOUR FROM survey_scheduled_at) * 60 + EXTRACT(MINUTES FROM survey_scheduled_at) + 15) >= ?", t.hour * 60 + t.min)
  }

  def self.find_or_initialize_by_call_sid_and_phone(call_sid, phone)
    Contact.find_or_initialize_by(call_sid: call_sid) do |contact|
      contact.phone = SmsChannel.clean_phone(phone)
    end
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

  def schedule_survey!
    self.abort_same_phone_surveys

    timespan = if self.pregnant || self.urgent
      1.week
    else
      1.month
    end
    self.survey_scheduled_at = Time.now.utc + timespan
    self.clear_survey_data
    self.save!
  end

  def abort_survey!
    self.survey_status = nil
    self.survey_scheduled_at = nil
    self.save!
  end

  def abort_same_phone_surveys
    Contact.where(phone: self.phone).surveys_ongoing_or_stalled.each do |contact|
      contact.abort_survey!
    end
  end

  def clear_survey_data
    self.survey_status = nil
    self.survey_updated_at = nil

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
