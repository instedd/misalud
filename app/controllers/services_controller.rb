class ServicesController < ApiController

  include CallFlowResponses

  def find_clinic
    # Sanitise input params
    opts = {
      lang: params[:lang],
      pregnancy: (params[:pregnancy] == PREGNANT),
      urgent: (params[:when] == WHEN_URGENT),
      borough: Borough[params[:where]].try(&:name),
      known_condition: (params[:knowncondition] == HAS_KNOWN_CONDITION),
      free_clinic: (params[:knowncondition] != HAS_KNOWN_CONDITION)
    }

    # Get clinics based on criteria on call's contact
    call_sid = params.delete(:CallSid)
    @contact = Contact.find_by(call_sid: call_sid)
    raise "Contact for call id #{call_sid || 'nil'} not found" if @contact.nil?
    @clinics = @contact.pick_clinics(opts)

    if @clinics.empty?
      text = t_to_say_node(:no_clinics_found)
      render xml: "<Response>#{text}</Response>"
      return
    end

    # Build response text: clinics names are to be read in English, and the rest in the user's locale
    nodes = [ t_to_say_node(:you_can_go_to) ]
    @clinics.each_with_index do |clinic, index|
      if (index == @clinics.size - 1) && (@clinics.size > 1)
        nodes << t_to_say_node(:or)
        nodes << to_say_node(clinic.name, "en")
      else
        nodes << to_say_node("#{clinic.name}, ", "en")
      end
    end

    render xml: "<Response>#{nodes.join("")}</Response>"
  end

  def get_clinics
    @contact = Contact.find_by(call_sid: params[:CallSid])
    @contact.tracking_status = "sms_info"
    @contact.save!

    variables = {}
    @contact.clinics.each_with_index do |clinic, index|
      schedule = @contact.urgent ? clinic.walk_in_schedule : clinic.schedule
      variables["clinic#{index + 1}"] = clinic.sms_info(@contact.urgent)
    end

    render json: variables
  end

  def status_callback
    contact = Contact.find_or_initialize_by_call_sid_and_phone(params[:CallSid], params[:From])

    case params[:CallStatus]
    when "in-progress"
      contact.tracking_status = "call_started"
      contact.clear_survey_data
      contact.save!
    when "failed"
      contact.tracking_status = "hung_up"
      contact.save!
    when "completed"
      contact.tracking_status = params[:sendsms] == "1" ? "sms_info" : "voice_info"
      contact.save!
      contact.schedule_survey!
    end

    head :ok
  end

  private

  def to_say_node(text, lang)
    "<Say language=\"#{lang}\">#{text}</Say>"
  end

  def t_to_say_node(key)
    to_say_node(I18n.t(key, locale: params[:lang]), params[:lang])
  end
end
