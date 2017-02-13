class ServicesController < ApplicationController

  include CallFlowResponses

  skip_before_action :verify_authenticity_token

  def find_clinic
    # Sanitise input params
    opts = {
      lang: params[:lang],
      pregnancy: (params[:pregnancy] == PREGNANT),
      urgent: (params[:when] == WHEN_URGENT),
      borough: Borough[params[:where]].try(&:name),
      free_clinic: (params[:knowncondition] != HAS_KNOWN_CONDITION)
    }

    # Get clinics based on criteria on call's contact
    call_sid = params.delete(:CallSid)
    @contact = Contact.find_by(call_sid: call_sid)
    raise "Contact for call id #{call_sid || 'nil'} not found" if @contact.nil?
    @clinics = @contact.pick_clinics(opts)

    # Build response text: clinics names are to be read in English, and the rest in the user's locale
    nodes = [ to_say_node(I18n.t(:you_can_go_to, locale: params[:lang]), params[:lang]) ]
    @clinics.each_with_index do |clinic, index|
      if (index == @clinics.size - 1) && (@clinics.size > 1)
        nodes << to_say_node(I18n.t(:or, locale: params[:lang]), params[:lang])
        nodes << to_say_node(clinic.short_name, "en")
      else
        nodes << to_say_node("#{clinic.short_name}, ", "en")
      end
    end

    render xml: "<Response>#{nodes.join("")}</Response>"
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

  private

  def to_say_node(text, lang)
    "<Say language=\"#{lang}\">#{text}</Say>"
  end
end
