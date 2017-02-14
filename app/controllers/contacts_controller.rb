class ContactsController < ApplicationController
  def index
  end

  def start_survey
    phone = Contact.find(params[:id]).phone
    MessageProcessor.new(SmsChannel.new).start_survey(phone)
    flash[:notice] = "Follow-up SMS survey to #{phone} has been sent"
    redirect_to contacts_path
  end
end
