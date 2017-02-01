class SmsChannel
  def initialize
    @twilio_client = Twilio::REST::Client.new Settings.twilio.sid, Settings.twilio.token
  end

  def send_sms(to, body)
    @twilio_client.messages.create(
      :from => Settings.twilio.phone_number,
      :to => to,
      :body => body
    )
  end

  def config_webhook(url)
    target_phone.update sms_url: url
  end

  def self.clean_phone(phone_number)
    phone_number.gsub(/[\+\-\s\(\)]/, '')
  end

  private

  def target_phone
    incoming_phones = @twilio_client.account.incoming_phone_numbers.list

    target_phone = incoming_phones.find do |phone|
      SmsChannel.clean_phone(phone.phone_number) == SmsChannel.clean_phone(Settings.twilio.phone_number)
    end

    unless target_phone
      raise "#{Settings.twilio.phone_number} was not found in your twilio account phone numbers"
    end

    target_phone
  end
end
