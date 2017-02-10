class ServicesController < ApplicationController

  skip_before_action :verify_authenticity_token

  def find_clinic
    text = if params[:lang] == "en"
      "You can go to New York City Free Clinic, Weill Cornell Community Clinic or Columbia Student Medical Outreach."
    else
      "Usted puede ir a New York City Free Clinic, Weill Cornell Community Clinic o Columbia Student Medical Outreach."
    end

    render xml: "<Response><Say>#{text}</Say></Response>"
  end

  def track_contact
    contact = Contact.find_or_initialize_by(phone: params[:phone_number]) do |contact|
      contact.survey_status = ""
      contact.survey_data = {}
    end
    contact.tracking_status = params[:tracking_status]
    if params[:tracking_status] == "call_started"
      contact.call_started_at = Time.now.utc
      # TODO schedule a background job for a 3 min timeout or update it on request
    end
    contact.save!

    head :ok
  end
end
