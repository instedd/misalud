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

def twilio_sms(phone, message)
  post "/twilio/sms", params: { From: phone, Body: message }
end


def start_surveys
  SurveyScheduler.run
end

class Integer
  def later
    Timecop.freeze(Time.now + self.seconds)
  end
end

class FakeSmsChannel
  def initialize
    @messages = []
  end

  def messages
    @messages
  end

  def send_sms(to, body)
    @messages << {to: to, body: body}
  end
end

include CallFlowResponses

RSpec.describe "Complete flow", type: :request do
  let(:phone) { "1234567" }
  let(:sid) { "345678" }
  let(:lang) { "es" }
  let!(:sms_channel) { FakeSmsChannel.new }
  let!(:clinics) do
    [Clinic.create!(short_name: "Clinic 1", borough: "manhattan"),
     Clinic.create!(short_name: "Clinic 2", borough: "manhattan"),
     Clinic.create!(short_name: "Clinic 3", borough: "manhattan")]
  end

  def contact
    Contact.find_or_initialize_by_phone(phone)
  end

  around(:each) do |example|
    SmsChannel.returned = sms_channel
    old_locale = I18n.locale
    I18n.locale = lang
    Timecop.freeze(Time.now)
    example.run
    Timecop.return
    I18n.locale = old_locale
    SmsChannel.returned = nil
  end

  def expect_messages
    sms_channel.messages.clear
    yield
    expect(sms_channel.messages.map { |m| m[:body] })
  end

  it "can run with a lazy user filling the survey" do
    expect_stats(inbound_calls: 0)
    verboice_start_call(sid, phone)
    expect_stats(inbound_calls: 1)
    verboice_find_clinic(sid, { lang: lang,
      pregnancy: NOT_PREGNANT,
      when: WHEN_URGENT,
      where: "1",
      knowncondition: HAS_KNOWN_CONDITION,
    })
    verboice_get_clinic(sid)
    expect(contact.clinics).to_not be_empty

    verboice_complete_call(sid, phone, sendsms: 1)
    expect_stats(voice_info: 0, sms_info: 1, followed_up: 0)

    expect(Contact.survey_ready_to_start.count).to eq(0)
    6.days.later
    expect(Contact.survey_ready_to_start.count).to eq(0)
    1.day.later
    expect(Contact.survey_ready_to_start.count).to eq(1)

    expect_messages {
      start_surveys
    }.to eq([I18n.t('survey.start_message')])

    expect(Contact.survey_ready_to_start.count).to eq(0)
    expect_stats(followed_up: 0, surveys_scheduled: 0, surveys_ongoing: 1, surveys_stalled: 0)
    25.hours.later
    expect_stats(followed_up: 0, surveys_scheduled: 0, surveys_ongoing: 0, surveys_stalled: 1)

    expect_messages {
      twilio_sms phone, "si"
    }.to include(a_string_starting_with(I18n.t('survey.which_clinic_did_you_choose')))

    expect_stats(followed_up: 0, surveys_scheduled: 0, surveys_ongoing: 1, surveys_stalled: 0)
    25.hours.later
    expect_stats(followed_up: 0, surveys_scheduled: 0, surveys_ongoing: 0, surveys_stalled: 1)

    expect_messages {
      twilio_sms phone, "1"
    }.to include(a_string_starting_with(I18n.t('survey.ask_satisfaction')))

    expect_messages {
      twilio_sms phone, "5"
    }.to include(a_string_starting_with(I18n.t('survey.can_we_call_later')))

    expect_stats(followed_up: 0, surveys_scheduled: 0, surveys_ongoing: 1, surveys_stalled: 0)

    expect_messages {
      twilio_sms phone, "no"
    }.to include(a_string_starting_with(I18n.t('survey.thanks')))

    expect_stats(followed_up: 1, surveys_scheduled: 0, surveys_ongoing: 0, surveys_stalled: 0)
  end
end
