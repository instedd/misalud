class WelcomeController < ApplicationController
  def index
    @inbound_calls = Contact.inbound_calls.count
    @hang_ups = Contact.hang_ups.count
    @voice_info = Contact.voice_info.count
    @sms_info = Contact.sms_info.count
    @followed_up = Contact.followed_up.count

    @surveys_scheduled = Contact.surveys_scheduled.count
    @surveys_ongoing = Contact.surveys_ongoing.count
    @surveys_stalled = Contact.surveys_stalled.count
  end

  def map
    @clinics = Clinic.all
    gon.clinics = @clinics
  end

  def start_survey
    MessageProcessor.new(SmsChannel.build).start_survey(params[:phone])
    redirect_to root_path
  end
end
