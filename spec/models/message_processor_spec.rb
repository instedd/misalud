require 'rails_helper'

RSpec.describe MessageProcessor, type: :model do
  let(:channel) { double("fake_sms_channel") }
  let(:subject) { MessageProcessor.new(channel) }
  before(:each) do
    (1..3).each do |i|
      Clinic.import_clinic i, {"name" => "Name #{i}"}
    end
  end

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
      expect(channel).to receive(:send_sms).with(phone, I18n.t('survey.start_message', locale: 'en'))
      subject.start_survey(phone)
    end

    it "should send message to channel with contact's language" do
      Contact.create!(phone: phone, tracking_status: 'sms_info', language: 'es')
      expect(channel).to receive(:send_sms).with(phone, I18n.t('survey.start_message', locale: 'es'))
      subject.start_survey(phone)
    end
  end

  describe "#accept" do
    let(:unkown_phone) { "7890476" }

    it "should noop for unkown numbers" do
      subject.accept(unkown_phone, "lorem ipsum")
    end
  end

  describe "survey tracking" do
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

  describe "survey answers" do
    let(:contact) { Contact.create!(phone: "465789", tracking_status: 'sms_info', language: 'en', clinic1: Clinic.all[0], clinic2: Clinic.all[1]) }

    it "should send answers via channel" do
      expect(channel).to receive(:send_sms).with(contact.phone, I18n.t('survey.start_message', locale: 'en'))
      subject.start_survey(contact.phone)

      expect(channel).to receive(:send_sms).with(contact.phone, "#{I18n.t('survey.which_clinic_did_you_choose', locale: 'en')} Reply with '1' for Name 1, '2' for Name 2")
      subject.accept contact.phone, "yes"

      expect(channel).to receive(:send_sms).with(contact.phone, "#{I18n.t('survey.ask_satisfaction', locale: 'en')}")
      subject.accept contact.phone, "2"

      expect(channel).to receive(:send_sms).with(contact.phone, "#{I18n.t('survey.can_we_call_later', locale: 'en')}")
      subject.accept contact.phone, "5"

      expect(channel).to receive(:send_sms).with(contact.phone, "#{I18n.t('survey.thanks', locale: 'en')}")
      subject.accept contact.phone, "no"
    end

    it "should send answers via channel in contact's language" do
      contact.update_column(:language, 'es')

      expect(channel).to receive(:send_sms).with(contact.phone, I18n.t('survey.start_message', locale: 'es'))
      subject.start_survey(contact.phone)

      expect(channel).to receive(:send_sms).with(contact.phone, "#{I18n.t('survey.which_clinic_did_you_choose', locale: 'es')} Conteste con '1' para Name 1, '2' para Name 2")
      subject.accept contact.phone, "yes"

      expect(channel).to receive(:send_sms).with(contact.phone, "#{I18n.t('survey.ask_satisfaction', locale: 'es')}")
      subject.accept contact.phone, "2"

      expect(channel).to receive(:send_sms).with(contact.phone, "#{I18n.t('survey.can_we_call_later', locale: 'es')}")
      subject.accept contact.phone, "5"

      expect(channel).to receive(:send_sms).with(contact.phone, "#{I18n.t('survey.thanks', locale: 'es')}")
      subject.accept contact.phone, "no"
    end
  end
end
