class WelcomeController < ApplicationController
  def index
    @received_calls = Contact.count
    @hang_ups = Contact.where(tracking_status: 'hung_up').count
    @completed_calls = Contact.where(tracking_status: ['voice_info', 'sms_info', 'followed_up']).count
    @sms_sent = Contact.where(sms_requested: true).count
    @surveys_started = Contact.where("survey_status IS NOT NULL").count
    @surveys_completed = Contact.where(survey_status: 'done').count
  end

  def start_survey
    phone = SmsChannel.clean_phone(params[:phone])
    MessageProcessor.new(SmsChannel.new).start_survey(phone)
    redirect_to root_path
  end
end
