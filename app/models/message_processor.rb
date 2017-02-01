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
          send_sms CLINIC_OPTIONS
        }
        r.no {
          update "pending_reason_not_seen", { "seen" => false }
          send_sms "Why? Reply 1. You couldn’t get there 2. Your health status changed 3. Cost 4. Went but rejected"
        }
        r.otherwise {
          send_sms "We didn't get that. Please reply 'yes' or 'no'."
        }
      end
    when "pending_clinic"
      respond_to do |r|
        r.digit(1,3) { |d|
          update "pending_satisfaction", { "clinic" => d }
          send_sms "Are you satisfied? 1 ok, 5 best experience."
        }
        r.otherwise {
          send_sms "We didn't get that. Please reply '1', '2' or '3'."
        }
      end
    when "pending_satisfaction"
      respond_to do |r|
        r.digit(1,5) { |d|
          update "pending_can_be_called", { "satisfaction" => d }
          send_sms "can we call you back to talk about your experience? #{REPLY_YES_NO}"
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
          send_sms "can we call you back to talk about your experience? #{REPLY_YES_NO}"
        }
        r.digit(4,4) { |d|
          update "pending_clinic_not_seen", { "reason_not_seen" => NOT_SEEN_REASON[d] }
          send_sms CLINIC_OPTIONS
        }
        r.otherwise {
          send_sms "We didn't get that. Please reply '1' to '4'."
        }
      end
    when "pending_clinic_not_seen"
      respond_to do |r|
        r.digit(1,3) { |d|
          update "pending_can_be_called", { "clinic" => d }
          send_sms "can we call you back to talk about your experience? #{REPLY_YES_NO}"
        }
        r.otherwise {
          send_sms "We didn't get that. Please reply '1', '2' or '3'."
        }
      end
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

  REPLY_YES_NO = "Reply yes or no"
  START_SURVEY = "Last time we recommend you some clinics. Where you seen by someone? #{REPLY_YES_NO}"
  CLINIC_OPTIONS = "Which one you choose? Reply with 1. for NYC Free Clinic, 2. for Weill Cornell, 3. for Columbia"
  NOT_SEEN_REASON = { 1 => "could_not_get_there", 2 => "health_change", 3 => "cost", 4 => "rejected" }

  private

  include MessageResponder::Helper

  def respond_to
    reply_to(@body) do |r|
      yield r
    end
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
