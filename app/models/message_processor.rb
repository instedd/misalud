class MessageProcessor
  def initialize(channel)
    @channel = channel
  end

  def accept(from, body)
    old_locale = I18n.locale

    @contact = Contact.find_by(phone: from)
    return unless @contact

    I18n.locale = @contact.language || "en"
    @body = body

    case @contact.survey_status
    when "pending_seen"
      respond_to do |r|
        r.yes {
          update "pending_clinic", { "survey_was_seen" => true }
          send_sms clinic_options
        }
        r.no {
          update "pending_reason_not_seen", { "survey_was_seen" => false }
          send_sms I18n.t("survey.why_not_seen")
        }
        r.otherwise {
          send_sms I18n.t('survey.error_yes_no')
        }
      end
    when "pending_clinic"
      respond_to do |r|
        r.digit(1,3) { |d|
          update "pending_satisfaction", { "survey_chosen_clinic_id" => @contact.clinic(d).try(:id) }
          send_sms I18n.t('survey.ask_satisfaction')
        }
        r.otherwise {
          send_sms I18n.t('survey.error_1_to_3')
        }
      end
    when "pending_satisfaction"
      respond_to do |r|
        r.digit(1,5) { |d|
          update "pending_can_be_called", { "survey_clinic_rating" => d }
          update_clinic_rating d
          send_sms I18n.t('survey.can_we_call_later')
        }
        r.otherwise {
          send_sms I18n.t('survey.error_1_to_5')
        }
      end
    when "pending_can_be_called"
      respond_to do |r|
        r.yes {
          update "done", { "survey_can_be_called" => true, "tracking_status" => "followed_up" }
          send_sms I18n.t('survey.thanks')
        }
        r.no {
          update "done", { "survey_can_be_called" => false, "tracking_status" => "followed_up" }
          send_sms I18n.t('survey.thanks')
        }
        r.otherwise {
          send_sms I18n.t('survey.error_yes_no')
        }
      end
    when "pending_reason_not_seen"
      respond_to do |r|
        r.digit(1,3) { |d|
          update "pending_can_be_called", { "survey_reason_not_seen" => NOT_SEEN_REASON[d] }
          send_sms I18n.t('survey.can_we_call_later')
        }
        r.digit(4,4) { |d|
          update "pending_clinic_not_seen", { "survey_reason_not_seen" => NOT_SEEN_REASON[d] }
          send_sms clinic_options
        }
        r.otherwise {
          send_sms I18n.t('survey.error_1_to_4')
        }
      end
    when "pending_clinic_not_seen"
      respond_to do |r|
        r.digit(1,3) { |d|
          update "pending_can_be_called", { "survey_chosen_clinic_id" => @contact.clinic(d).try(:id) }
          send_sms I18n.t('survey.can_we_call_later')
        }
        r.otherwise {
          send_sms I18n.t('survey.error_1_to_3')
        }
      end
    end
  ensure
    I18n.locale = old_locale
  end

  def start_survey(phone)
    contact = Contact.find_or_initialize_by_phone(phone)
    unless contact.persisted?
      # Values for fresh contacts, should not happen actually
      contact.tracking_status = "sms_info"
    end

    contact.clear_survey_data
    contact.survey_status = "pending_seen"
    contact.survey_updated_at = Time.now.utc
    contact.save!

    @channel.send_sms(phone, I18n.t('survey.start_message', locale: contact.language || 'en'))
  end

  NOT_SEEN_REASON = { 1 => "could_not_get_there", 2 => "health_change", 3 => "cost", 4 => "rejected" }

  private

  include MessageResponder::Helper

  def respond_to
    reply_to(@body) do |r|
      yield r
    end
  end

  def clinic_options
    "#{I18n.t('survey.which_clinic_did_you_choose')} #{I18n.t('survey.reply_with')} #{clinic_short_names_as_options}"
  end

  def clinic_short_names_as_options
    options = ""
    @contact.clinics.each_with_index do |clinic, index|
      options << ", " if options != ""
      options << "'#{index+1}' #{I18n.t(:for)} #{clinic.display_name}"
    end
    options
  end

  def send_sms(body)
    @channel.send_sms(@contact.phone, body)
  end

  def update(next_status, data)
    @contact.survey_status = next_status
    @contact.survey_updated_at = Time.now.utc
    @contact.update_attributes!(data)
  end

  def update_clinic_rating(rating)
    @contact.survey_chosen_clinic.add_rating!(rating)
  end
end
