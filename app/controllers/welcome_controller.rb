class WelcomeController < ApplicationController
  def index
    @inbound_calls = Contact.count
    @hang_ups = Contact.where(tracking_status: 'hung_up').count
    @voice_info = Contact.where(tracking_status: 'voice_info').count
    @sms_info = Contact.where(tracking_status: 'sms_info').count

    @surveys_started = Contact.where("survey_status IS NOT NULL").count
    @surveys_completed = Contact.where(survey_status: 'done').count
  end

  def map
    @clinics = Clinic.all
    gon.clinics = @clinics
  end

  def start_survey
    phone = SmsChannel.clean_phone(params[:phone])
    MessageProcessor.new(SmsChannel.new).start_survey(phone)
    redirect_to root_path
  end
end
