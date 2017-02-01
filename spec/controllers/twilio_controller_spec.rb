require 'rails_helper'

RSpec.describe TwilioController, type: :controller do

  describe "GET #sms" do
    it "returns http success" do
      post :sms, params: { :From => "", :Body => "" }
      expect(response).to have_http_status(:success)
    end
  end

end
