require 'rails_helper'

RSpec.describe ServicesController, type: :controller do

  describe "GET #find_clinic" do

    before(:each) do
      @clinics = [
        Clinic.create!(resmap_id: 1, short_name: "Clinic 1", free_clinic: true, borough: "manhattan"),
        Clinic.create!(resmap_id: 2, short_name: "Clinic 2", free_clinic: true, borough: "brooklyn"),
        Clinic.create!(resmap_id: 3, short_name: "Clinic 3", free_clinic: true, borough: "brooklyn"),
        Clinic.create!(resmap_id: 4, short_name: "Clinic 4", free_clinic: false, borough: "brooklyn")
      ]
    end

    it "returns text for clinics" do
      get :find_clinic, params: {
        "lang" => "es",
        "pregnancy" => CallFlowResponses::NOT_PREGNANT,
        "when" => CallFlowResponses::WHEN_URGENT,
        "where" => "2",
        "knowncondition" => CallFlowResponses::NO_KNOWN_CONDITION
      }

      clinics = assigns(:clinics)
      expect(clinics.size).to eq(3)
      expect(clinics).to match_array([@clinics[1], @clinics[2], @clinics[3]])

      expect(response).to have_http_status(:success)
      expect(response.body).to include(@clinics[1].short_name)
      expect(response.body).to include(@clinics[2].short_name)
      expect(response.body).to include(@clinics[3].short_name)
    end
  end

end
