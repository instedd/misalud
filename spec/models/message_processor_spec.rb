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

  describe "survey" do
    let(:phone) { "465789" }

    it "should track responses (seen)" do
      allow(channel).to receive(:send_sms)

      subject.start_survey(phone)
      subject.accept phone, "yes"
      subject.accept phone, "2"
      subject.accept phone, "5"
      subject.accept phone, "no"

      contact = Contact.find_by(phone: phone)
      expect(contact.survey_data).to eq({
        "seen" => true,
        "clinic" => 2,
        "satisfaction" => 5,
        "can_be_called" => false
      })
    end

    it "should track responses (rejected)" do
      allow(channel).to receive(:send_sms)

      subject.start_survey(phone)
      subject.accept phone, "no"
      subject.accept phone, "4"
      subject.accept phone, "1"
      subject.accept phone, "yes"

      contact = Contact.find_by(phone: phone)
      expect(contact.survey_data).to eq({
        "seen" => false,
        "clinic" => 1,
        "reason_not_seen" => "rejected",
        "can_be_called" => true
      })
    end

    it "should track responses (cost)" do
      allow(channel).to receive(:send_sms)

      subject.start_survey(phone)
      subject.accept phone, "no"
      subject.accept phone, "3"
      subject.accept phone, "yes"

      contact = Contact.find_by(phone: phone)
      expect(contact.survey_data).to eq({
        "seen" => false,
        "reason_not_seen" => "cost",
        "can_be_called" => true
      })
    end
  end
end