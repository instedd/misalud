require 'rails_helper'

RSpec.describe ServicesController, type: :controller do

  describe "POST #track_contact" do
    let(:phone) { "1999345567" }

    Contact::TRACKING_STATUS.each do |status|
      it "creates contact #{status}" do
        expect {
          post :track_contact, params: { phone_number: phone, tracking_status: status }
        }.to change(Contact, :count).by(1)
        expect(response).to have_http_status(:success)

        contact = Contact.find_by(phone: phone)
        expect(contact.tracking_status).to eq(status)
      end

      it "updates contact #{status}" do
        Contact.create! phone: phone, tracking_status: "call_started"

        expect {
          post :track_contact, params: { phone_number: phone, tracking_status: status }
        }.to change(Contact, :count).by(0)
        expect(response).to have_http_status(:success)

        contact = Contact.find_by(phone: phone)
        expect(contact.tracking_status).to eq(status)
      end
    end

    it "tracks when the call started only for call_started" do
      post :track_contact, params: { phone_number: phone, tracking_status: "call_started" }
      contact = Contact.find_by(phone: phone)
      call_started_at = contact.call_started_at
      expect(call_started_at).to_not be_nil

      post :track_contact, params: { phone_number: phone, tracking_status: "voice_info" }
      contact.reload
      expect(contact.call_started_at).to eq(call_started_at)
    end
  end

end
