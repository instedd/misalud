require 'rails_helper'

def expect_can_view_dashboard
  get "/"
  expect(response).to have_http_status(:success)
end

def expect_stats(options)
  expect_can_view_dashboard

  options.each do |key, value|
    expect(Contact.send(key).count).to eq(value)
  end
end

def verboice_start_call(sid, phone)
  post "/services/status-callback", params: { From: phone, CallSid: sid, CallStatus: "in-progress" }
  expect(response).to have_http_status(:success)
end

def verboice_complete_call(sid, phone, params)
  post "/services/status-callback", params: { From: phone, CallSid: sid, CallStatus: "completed" }.merge(params)
  expect(response).to have_http_status(:success)
end

def verboice_find_clinic(sid, params)
  post "/services/find-clinic", params: { CallSid: sid }.merge(params)
  expect(response).to have_http_status(:success)
end

def verboice_get_clinic(sid)
  post "/services/get-clinics", params: { CallSid: sid }
  expect(response).to have_http_status(:success)
end

class Integer
  def later
    Timecop.freeze(Time.now + self.seconds)
  end
end

include CallFlowResponses

RSpec.describe "Complete flow", type: :request do
  let(:phone) { "1234567" }
  let(:sid) { "345678" }

  before do
    Timecop.freeze(Time.now)
  end

  after do
    Timecop.return
  end

  it "can run" do
    expect_stats(inbound_calls: 0)
    verboice_start_call(sid, phone)
    expect_stats(inbound_calls: 1)
    verboice_find_clinic(sid, { lang: "es",
      pregnancy: NOT_PREGNANT,
      when: WHEN_URGENT,
      where: "1",
      knowncondition: HAS_KNOWN_CONDITION,
    })
    verboice_get_clinic(sid)
    verboice_complete_call(sid, phone, sendsms: 1)
    expect_stats(voice_info: 0, sms_info: 1, followed_up: 0)

    expect(Contact.survey_ready_to_start.count).to eq(0)
    6.days.later
    expect(Contact.survey_ready_to_start.count).to eq(0)
    1.day.later
    expect(Contact.survey_ready_to_start.count).to eq(1)
  end
end
