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

    # Get clinics based on criteria
    @clinics = Clinic.pick(opts)

    # Build response text, to be replaced by recordings
    connector = ", #{I18n.t(:or, locale: params[:lang])} "
    text = @clinics.map(&:short_name).to_sentence(two_words_connector: connector, last_word_connector: connector)
    text = "#{I18n.t(:you_can_go_to, locale: params[:lang])} #{text}"

    render xml: "<Response><Say>#{text}</Say></Response>"
  end

end
