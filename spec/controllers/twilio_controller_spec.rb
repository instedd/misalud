require 'rails_helper'

RSpec.describe TwilioController, type: :controller do

  describe "GET #sms" do
    it "returns http success" do
      @request.headers.merge(api_http_login_header)
      post :sms, params: { :From => "", :Body => "" }
      expect(response).to have_http_status(:success)
    end
  end

end
