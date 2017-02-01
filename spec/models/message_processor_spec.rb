require 'rails_helper'

RSpec.describe MessageProcessor, type: :model do
  let(:channel) { double("fake_sms_channel") }
  let(:subject) { MessageProcessor.new(channel) }

  describe "#start_survey" do
    let(:phone) { "123456" }

    it "creates a new contact" do
      allow(channel).to receive(:send_sms)

      expect {
        subject.start_survey(phone)
      }.to change(Contact, :count).by(1)
    end

    it "reuse existing contact cleaning up survey data" do
      allow(channel).to receive(:send_sms)

      subject.start_survey(phone)
      contact = Contact.find_by(phone: phone)
      contact.survey_status = "lorem"
      contact.survey_data = {a: 1}
      contact.save!

      expect {
        subject.start_survey(phone)
      }.to change(Contact, :count).by(0)

      contact = Contact.find_by(phone: phone)
      expect(contact.survey_status).to eq("pending_seen")
      expect(contact.survey_data).to eq({})
    end

    it "should send message to channel" do
      expect(channel).to receive(:send_sms).with(phone, MessageProcessor::START_SURVEY)
      subject.start_survey(phone)
    end
  end

  describe "#accept" do
    let(:unkown_phone) { "7890476" }

    it "should noop for unkown numbers" do
      subject.accept(unkown_phone, "lorem ipsum")
    end
  end
end
