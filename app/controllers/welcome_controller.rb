class WelcomeController < ApplicationController
  def index
  end

  def start_survey
    phone = SmsChannel.clean_phone(params[:phone])
    MessageProcessor.new(SmsChannel.new).start_survey(phone)
    redirect_to root_path
  end
end
