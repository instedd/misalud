class ContactsController < ApplicationController
  def index
  end

  def start_survey
    contact = Contact.find(params[:id])
    MessageProcessor.new(SmsChannel.build).start_survey(contact)
    flash[:notice] = "Follow-up SMS survey to #{contact.phone} has been sent"
    redirect_to contacts_path
  end
end
