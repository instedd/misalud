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

end
