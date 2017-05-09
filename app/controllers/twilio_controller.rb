class TwilioController < ApiController
  def sms
    MessageProcessor.new(SmsChannel.build).accept(
      SmsChannel.clean_phone(params[:From]),
      params[:Body]
    )
    head :ok
  end
end
