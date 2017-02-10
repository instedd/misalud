class ServicesController < ApplicationController

  skip_before_action :verify_authenticity_token

  def find_clinic
    contact = Contact.find_by(call_sid: params[:CallSid])
    contact.pick_clinics

    text = if params[:lang] == "en"
      clinic_names = contact.clinics.map(&:name).to_sentence(words_connector: ", ", two_words_connector: " or ")
      "You can go to #{clinic_names}."
    else
      clinic_names = contact.clinics.map(&:name).to_sentence(words_connector: ", ", two_words_connector: " o ")
      "Usted puede ir a #{clinic_names}."
    end

    render xml: "<Response><Say>#{text}</Say></Response>"
  end

  def get_clinics
    contact = Contact.find_by(call_sid: params[:CallSid])

    variables = {}
    contact.clinics.each_with_index do |clinic, index|
      # TODO add borough
      # TODO add send walk_in_schedule if appropiate
      variables["clinic#{index + 1}"] = "#{clinic.name}, #{clinic.address}, #{clinic.schedule}"
    end

    render json: variables
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
