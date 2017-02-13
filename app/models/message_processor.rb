class MessageProcessor
  def initialize(channel)
    @channel = channel
  end

  def accept(from, body)
    @contact = Contact.find_by(phone: from)
    return unless @contact
    @body = body

    case @contact.survey_status
    when "pending_seen"
      respond_to do |r|
        r.yes {
          update "pending_clinic", { "seen" => true }
          send_sms clinic_options
        }
        r.no {
          update "pending_reason_not_seen", { "seen" => false }
          send_sms "Why? Respond with one of the following numbers: 1.You couldn’t get there  2.Your health status changed  3.Cost  4.Went but refused service"
        }
        r.otherwise {
          send_sms "We didn't get that. Please reply 'yes' or 'no'."
        }
      end
    when "pending_clinic"
      respond_to do |r|
        r.digit(1,3) { |d|
          update "pending_satisfaction", { "clinic" => d }
          send_sms "Are you satisfied? 1. worst experience, 5. best experience."
        }
        r.otherwise {
          send_sms "We didn't get that. Please reply '1', '2' or '3'."
        }
      end
    when "pending_satisfaction"
      respond_to do |r|
        r.digit(1,5) { |d|
          update "pending_can_be_called", { "satisfaction" => d }
          send_sms CAN_BE_CALLED
        }
        r.otherwise {
          send_sms "We didn't get that. Please reply '1' to '5'."
        }
      end
    when "pending_can_be_called"
      respond_to do |r|
        r.yes {
          update "done", { "can_be_called" => true }
          send_sms "Thank you!"
        }
        r.no {
          update "done", { "can_be_called" => false }
          send_sms "Thank you!"
        }
        r.otherwise {
          send_sms "We didn't get that. Please reply 'yes' or 'no'."
        }
      end
    when "pending_reason_not_seen"
      respond_to do |r|
        r.digit(1,3) { |d|
          update "pending_can_be_called", { "reason_not_seen" => NOT_SEEN_REASON[d] }
          send_sms CAN_BE_CALLED
        }
        r.digit(4,4) { |d|
          update "pending_clinic_not_seen", { "reason_not_seen" => NOT_SEEN_REASON[d] }
          send_sms clinic_options
        }
        r.otherwise {
          send_sms "We didn't get that. Please reply '1' to '4'."
        }
      end
    when "pending_clinic_not_seen"
      respond_to do |r|
        r.digit(1,3) { |d|
          update "pending_can_be_called", { "clinic" => d }
          send_sms CAN_BE_CALLED
        }
        r.otherwise {
          send_sms "We didn't get that. Please reply '1', '2' or '3'."
        }
      end
    end
  end

  def start_survey(phone)
    contact = Contact.find_or_initialize_by(phone: phone) do |contact|
      # values for fresh contacts, should not happen actually
      contact.tracking_status = "sms_info"
    end

    contact.survey_status = "pending_seen"
    contact.survey_data = {}
    contact.save!

    @channel.send_sms(phone, START_SURVEY)
  end

  REPLY_YES_NO = "Reply yes or no"
  START_SURVEY = "Last time we recommend some clinics to you. Were you seen by someone? #{REPLY_YES_NO}"
  CLINIC_OPTIONS_PREFIX = "Which one did you choose? Reply with "
  CAN_BE_CALLED = "Can we call you back later to talk about your experience? #{REPLY_YES_NO}"
  NOT_SEEN_REASON = { 1 => "could_not_get_there", 2 => "health_change", 3 => "cost", 4 => "rejected" }

  private

  include MessageResponder::Helper

  def respond_to
    reply_to(@body) do |r|
      yield r
    end
  end

  def clinic_options
    "#{CLINIC_OPTIONS_PREFIX} #{clinic_short_names_as_options}"
  end

  def clinic_short_names_as_options
    options = ""
    @contact.clinics.each_with_index do |clinic, index|
      options << ", " if options != ""
      options << "#{index+1}. for #{clinic.short_name}"
    end
    options
  end

  def send_sms(body)
    @channel.send_sms(@contact.phone, body)
  end

  def update(next_status, data)
    @contact.survey_status = next_status
    @contact.survey_data = @contact.survey_data.merge(data)
    @contact.save!
  end
end
