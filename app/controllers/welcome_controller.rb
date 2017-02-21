class WelcomeController < ApplicationController
  def index
    @inbound_calls = Contact.count
    @hang_ups = Contact.where(tracking_status: 'hung_up').count
    @voice_info = Contact.where(tracking_status: 'voice_info').count
    @sms_info = Contact.where(tracking_status: 'sms_info').count
    @followed_up = Contact.where(tracking_status: 'followed_up').count


    @surveys_scheduled = Contact.where("tracking_status <> 'followed_up' AND survey_status IS NULL AND survey_scheduled_at IS NOT NULL").count
    surveys_ongoing_or_stalled = Contact.where("tracking_status <> 'followed_up' AND survey_status IS NOT NULL")
    @surveys_ongoing = surveys_ongoing_or_stalled.where("survey_updated_at >= ?", 1.day.ago).count
    @surveys_stalled = surveys_ongoing_or_stalled.where("survey_updated_at < ?", 1.day.ago).count
  end

  def map
    @clinics = Clinic.all
    gon.clinics = @clinics
  end

  def start_survey
    MessageProcessor.new(SmsChannel.new).start_survey(params[:phone])
    redirect_to root_path
  end
end
