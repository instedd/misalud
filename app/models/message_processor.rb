class MessageProcessor
  def initialize(channel)
    @channel = channel
  end

  def accept(from, body)
    contact = Contact.find_by(phone: from)
    return unless contact

    case contact.survey_status
    when "pending_seen"
    when "pending_clinic"
    when "pending_satisfaction"
    when "pending_can_be_called"
    when "pending_reason_not_seen"
    when "pending_clinic_not_seen"
    end
  end

  def start_survey(phone)
    Contact.find_or_create_by(phone: phone).tap do |contact|
      contact.survey_status = "pending_seen"
      contact.survey_data = {}
      contact.save!
    end

    @channel.send_sms(phone, START_SURVEY)
  end

  START_SURVEY = "Last time we recommend you some clinics. Where you seen by someone? Reply yes or no."
end
