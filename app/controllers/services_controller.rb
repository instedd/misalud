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
    contact = Contact.find_or_initialize_by(phone: params[:phone_number])
    contact.tracking_status = params[:tracking_status]
    contact.save!

    head :ok
  end

  def status_callback
    contact = Contact.find_or_initialize_by(phone: params[:From])

    case params[:CallStatus]
    when "in-progress"
      contact.tracking_status = "call_started"
      contact.call_sid = params[:CallSid]
    when "failed"
      contact.tracking_status = "hung_up"
    when "completed"
      contact.tracking_status = "voice_info"
    end

    contact.save!

    head :ok
  end
end
