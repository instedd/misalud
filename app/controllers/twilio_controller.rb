class TwilioController < ApplicationController
  skip_before_action :verify_authenticity_token

  def sms
    MessageProcessor.new(SmsChannel.new).accept(
      SmsChannel.clean_phone(params[:From]),
      params[:Body]
    )
    head :ok
  end
end