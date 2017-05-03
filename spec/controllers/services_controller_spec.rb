require 'rails_helper'

RSpec.describe ServicesController, type: :controller do

  describe "GET #find-clinic" do

    let!(:contact) {
      Contact.create!(call_sid: 100, phone: "9991000", tracking_status: "call_started")
    }

    let!(:clinics) do
      [Clinic.create!(resmap_id: 1, short_name: "Clinic 1", short_name: "Cl 1", free_clinic: true, borough: "manhattan"),
       Clinic.create!(resmap_id: 2, short_name: "Clinic 2", short_name: "Cl 2", free_clinic: true, borough: "brooklyn"),
       Clinic.create!(resmap_id: 3, short_name: "Clinic 3", short_name: "Cl 3", free_clinic: true, borough: "brooklyn"),
       Clinic.create!(resmap_id: 4, short_name: "Clinic 4", short_name: "Cl 4", free_clinic: false, borough: "brooklyn")]
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

      expect(contact.reload.pregnant).to eq(false)
      expect(contact.urgent).to eq(true)
      expect(contact.borough).to eq("brooklyn")
      expect(contact.known_condition).to eq(false)
      expect(contact.language).to eq("es")
    end

    it "returns message for no clinics" do
      get :find_clinic, params: {
        "CallSid" => 100,
        "lang" => "es",
        "pregnancy" => CallFlowResponses::NOT_PREGNANT,
        "when" => CallFlowResponses::WHEN_URGENT,
        "where" => "5",
        "knowncondition" => CallFlowResponses::NO_KNOWN_CONDITION
      }

      found_contact = assigns(:contact)
      expect(found_contact).to eq(contact)

      actual_clinics = assigns(:clinics)
      expect(actual_clinics.size).to eq(0)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("#{I18n.t('no_clinics_found', locale: 'es')}")

      expect(contact.reload.pregnant).to eq(false)
      expect(contact.urgent).to eq(true)
      expect(contact.borough).to eq("staten_island")
      expect(contact.known_condition).to eq(false)
      expect(contact.language).to eq("es")
    end
  end

  describe "POST #status_callback" do
    let(:phone) { "1999345567" }
    let(:call_sid) { "465789" }
    let(:next_call_sid) { "876543" }
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

    it "creates a contact for each in-progress callback" do
      expect {
        post :status_callback, params: { CallStatus: "in-progress", From: phone, CallSid: call_sid }
      }.to change(Contact, :count).by(1)
      expect(response).to have_http_status(:success)

      expect {
        post :status_callback, params: { CallStatus: "in-progress", From: phone, CallSid: next_call_sid }
      }.to change(Contact, :count).by(1)
      expect(response).to have_http_status(:success)
    end

    it "marks as hung_up on failed" do
      post :status_callback, params: { CallStatus: "in-progress", From: phone, CallSid: call_sid }

      expect {
        post :status_callback, params: { CallStatus: "failed", CallSid: call_sid }
      }.to change(Contact, :count).by(0)
      expect(response).to have_http_status(:success)

      expect(contact.tracking_status).to eq("hung_up")
    end

    it "marks as voice_info on completed" do
      post :status_callback, params: { CallStatus: "in-progress", From: phone, CallSid: call_sid }

      expect {
        post :status_callback, params: { CallStatus: "completed", CallSid: call_sid }
      }.to change(Contact, :count).by(0)
      expect(response).to have_http_status(:success)

      expect(contact.tracking_status).to eq("voice_info")
    end

    it "marks as sms_info on completed with sendsms=1" do
      post :status_callback, params: { CallStatus: "in-progress", From: phone, CallSid: call_sid }

      expect {
        post :status_callback, params: { CallStatus: "completed", CallSid: call_sid }
      }.to change(Contact, :count).by(0)
      expect(response).to have_http_status(:success)

      expect(contact.tracking_status).to eq("voice_info")
    end
  end

  describe "GET #get_clinics" do

    let(:clinic1) { Clinic.create!(resmap_id: 1, name: "Clinic 1", short_name: "Cl 1", address: "ADDRESS1", schedule: "SCHEDULE", walk_in_schedule: "WALK_IN_SCHEDULE") }
    let(:clinic2) { Clinic.create!(resmap_id: 2, name: "Clinic 2", short_name: "Cl 2", address: "ADDRESS2", borough: "staten_island", schedule: "SCHEDULE", walk_in_schedule: "WALK_IN_SCHEDULE") }
    let(:clinic3) { Clinic.create!(resmap_id: 3, name: "Clinic 3", short_name: "Cl 3", address: "ADDRESS3", borough: "manhattan") }

    it "retrieves clinics for contact" do
      contact = Contact.create!(phone: "9991000", call_sid: 100, urgent: false, tracking_status: "voice_info", clinic1: clinic1, clinic2: clinic2, clinic3: clinic3)

      get :get_clinics, params: { CallSid: 100 }

      expect(assigns(:contact)).to eq(contact)
      variables = JSON.parse(response.body.to_s)

      expect(variables["clinic1"]).to eq("Clinic 1, ADDRESS1, SCHEDULE")
      expect(variables["clinic2"]).to eq("Clinic 2, ADDRESS2, Staten Island, SCHEDULE")
      expect(variables["clinic3"]).to eq("Clinic 3, ADDRESS3, Manhattan")
    end

    it "retrieves clinics for contact with walk in schedule" do
      contact = Contact.create!(phone: "9991000", call_sid: 100, urgent: true, tracking_status: "voice_info", clinic1: clinic1, clinic2: clinic2, clinic3: clinic3)

      get :get_clinics, params: { CallSid: 100 }

      expect(assigns(:contact)).to eq(contact)
      variables = JSON.parse(response.body.to_s)

      expect(variables["clinic1"]).to eq("Clinic 1, ADDRESS1, WALK_IN_SCHEDULE")
      expect(variables["clinic2"]).to eq("Clinic 2, ADDRESS2, Staten Island, WALK_IN_SCHEDULE")
      expect(variables["clinic3"]).to eq("Clinic 3, ADDRESS3, Manhattan")
    end

    it "tracks contact as sms_info requested" do
      contact = Contact.create!(phone: "9991000", call_sid: 100, urgent: true, tracking_status: "voice_info", clinic1: clinic1, clinic2: clinic2, clinic3: clinic3)

      get :get_clinics, params: { CallSid: 100 }

      expect(contact.reload.tracking_status).to eq("sms_info")
    end

  end
end
