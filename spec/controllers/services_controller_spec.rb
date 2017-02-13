require 'rails_helper'

RSpec.describe ServicesController, type: :controller do

  describe "GET #find_clinic" do

    let!(:contact) {
      Contact.create!(call_sid: 100, phone: "9991000", tracking_status: "call_started")
    }

    let!(:clinics) do
      [Clinic.create!(resmap_id: 1, short_name: "Clinic 1", free_clinic: true, borough: "manhattan"),
       Clinic.create!(resmap_id: 2, short_name: "Clinic 2", free_clinic: true, borough: "brooklyn"),
       Clinic.create!(resmap_id: 3, short_name: "Clinic 3", free_clinic: true, borough: "brooklyn"),
       Clinic.create!(resmap_id: 4, short_name: "Clinic 4", free_clinic: false, borough: "brooklyn")]
    end

    it "returns text for clinics" do
      get :find_clinic, params: {
        "CallSid" => 100,
        "lang" => "es",
        "pregnancy" => CallFlowResponses::NOT_PREGNANT,
        "when" => CallFlowResponses::WHEN_URGENT,
        "where" => "2",
        "knowncondition" => CallFlowResponses::NO_KNOWN_CONDITION
      }

      found_contact = assigns(:contact)
      expect(found_contact).to eq(contact)

      actual_clinics = assigns(:clinics)
      expect(actual_clinics.size).to eq(3)
      expect(actual_clinics).to contain_exactly(clinics[1], clinics[2], clinics[3])

      expect(response).to have_http_status(:success)
      expect(response.body).to include(clinics[1].short_name)
      expect(response.body).to include(clinics[2].short_name)
      expect(response.body).to include(clinics[3].short_name)
    end
  end

  describe "POST #track_contact" do
    let(:phone) { "1999345567" }
    let(:contact) { contact = Contact.find_by(phone: phone) }

    Contact::TRACKING_STATUS.each do |status|
      it "creates contact #{status}" do
        expect {
          post :track_contact, params: { phone_number: phone, tracking_status: status }
        }.to change(Contact, :count).by(1)
        expect(response).to have_http_status(:success)

        expect(contact.tracking_status).to eq(status)
      end

      it "updates contact #{status}" do
        Contact.create! phone: phone, tracking_status: "call_started"

        expect {
          post :track_contact, params: { phone_number: phone, tracking_status: status }
        }.to change(Contact, :count).by(0)
        expect(response).to have_http_status(:success)

        expect(contact.tracking_status).to eq(status)
      end
    end

    it "tracks when the call started only for call_started" do
      post :track_contact, params: { phone_number: phone, tracking_status: "call_started" }
      call_started_at = contact.call_started_at
      expect(call_started_at).to_not be_nil

      post :track_contact, params: { phone_number: phone, tracking_status: "voice_info" }
      contact.reload
      expect(contact.call_started_at).to eq(call_started_at)
    end
  end

  describe "POST #status_callback" do
    let(:phone) { "1999345567" }
    let(:call_sid) { "465789" }
    let(:contact) { contact = Contact.find_by(phone: phone) }

    it "creates a contact on first in-progress callback" do
      expect {
        post :status_callback, params: { CallStatus: "in-progress", From: phone, CallSid: call_sid }
      }.to change(Contact, :count).by(1)
      expect(response).to have_http_status(:success)

      expect(contact).to_not be_nil
      expect(contact.tracking_status).to eq("call_started")
      expect(contact.call_started_at).to_not be_nil
      expect(contact.call_sid).to eq(call_sid)
    end

    it "marks as hung_up on failed" do
      post :status_callback, params: { CallStatus: "in-progress", From: phone, CallSid: call_sid }

      expect {
        post :status_callback, params: { CallStatus: "failed", From: phone }
      }.to change(Contact, :count).by(0)
      expect(response).to have_http_status(:success)

      expect(contact.tracking_status).to eq("hung_up")
    end

    it "marks as voice_info on completed" do
      post :status_callback, params: { CallStatus: "in-progress", From: phone, CallSid: call_sid }

      expect {
        post :status_callback, params: { CallStatus: "completed", From: phone }
      }.to change(Contact, :count).by(0)
      expect(response).to have_http_status(:success)

      expect(contact.tracking_status).to eq("voice_info")
    end
  end

  describe "POST #find-clinic" do
    let(:phone) { "1999345567" }
    let(:call_sid) { "465789" }
    let(:contact) { contact = Contact.find_by(phone: phone) }

    before(:each) do
      (1..20).each do |i|
        Clinic.import_clinic i, {"name" => "Name #{i}"}
      end
    end

    before(:each) do
      post :status_callback, params: { CallStatus: "in-progress", From: phone, CallSid: call_sid }
    end

    it "should find contact by call_sid" do
      expect(contact.clinics).to be_empty
      post :find_clinic, params: { CallSid: call_sid }
      contact.reload
      expect(contact.clinics).to_not be_empty
    end
  end

end
