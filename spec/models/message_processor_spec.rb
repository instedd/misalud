require 'rails_helper'

RSpec.describe MessageProcessor, type: :model do
  let(:channel) { double("fake_sms_channel") }
  let(:subject) { MessageProcessor.new(channel) }

  (1..3).each do |i|
    let!("clinic#{i}") do
      Clinic.import_clinic i, {"name" => "Name #{i}"}
    end
  end

  describe "#start_survey" do
    let(:phone) { "123456" }
    let!(:contact) { Contact.create!(phone: phone, tracking_status: 'sms_info', language: 'en', clinic1: clinic1, clinic2: clinic2, clinic3: clinic3) }

    it "should clean up survey data" do
      allow(channel).to receive(:send_sms)

      subject.start_survey(contact)
      contact = Contact.find_by(phone: phone)
      contact.survey_status = "lorem"
      contact.survey_was_seen = true
      contact.survey_can_be_called = true
      contact.save!

      expect {
        subject.start_survey(contact)
      }.to change(Contact, :count).by(0)

      contact = Contact.find_by(phone: phone)
      expect(contact.survey_status).to eq("pending_seen")
      expect(contact.survey_was_seen).to be_nil
      expect(contact.survey_can_be_called).to be_nil
    end

    it "should abort pending survey of same number" do
      allow(channel).to receive(:send_sms)

      subject.start_survey(contact)

      expect(Contact.surveys_ongoing).to include(contact)

      new_contact = Contact.create!(phone: phone, tracking_status: 'sms_info', language: 'en', clinic1: clinic1, clinic2: clinic2, clinic3: clinic3)
      subject.start_survey(new_contact)

      expect(Contact.surveys_ongoing).to_not include(contact)
      expect(Contact.surveys_ongoing).to include(new_contact)
    end

    it "should abort scheduled survey of same number" do
      allow(channel).to receive(:send_sms)

      contact.survey_status = nil
      contact.survey_scheduled_at = Time.now.utc + 1.day
      contact.save!

      expect(Contact.surveys_scheduled).to include(contact)

      new_contact = Contact.create!(phone: phone, tracking_status: 'sms_info', language: 'en', clinic1: clinic1, clinic2: clinic2, clinic3: clinic3)
      subject.start_survey(new_contact)

      contact.reload
      expect(contact.survey_status).to be_nil
      expect(contact.survey_scheduled_at).to be_nil

      expect(Contact.surveys_scheduled).to_not include(contact)
      expect(Contact.surveys_ongoing).to include(new_contact)
    end

    it "should not change the completed surveys of same number" do
      allow(channel).to receive(:send_sms)

      subject.start_survey(contact)
      contact.tracking_status = "followed_up"
      contact.survey_was_seen = true
      contact.save!

      expect(Contact.followed_up).to include(contact)

      new_contact = Contact.create!(phone: phone, tracking_status: 'sms_info', language: 'en', clinic1: clinic1, clinic2: clinic2, clinic3: clinic3)
      subject.start_survey(new_contact)

      contact.reload
      expect(Contact.followed_up).to include(contact)
      expect(contact.survey_was_seen).to eq(true)
    end

    it "should send message to channel" do
      expect(channel).to receive(:send_sms).with(phone, I18n.t('survey.start_message', locale: 'en'))
      subject.start_survey(contact)
    end

    it "should send message to channel with contact's language" do
      contact = Contact.create!(phone: phone, tracking_status: 'sms_info', language: 'es')
      expect(channel).to receive(:send_sms).with(phone, I18n.t('survey.start_message', locale: 'es'))
      subject.start_survey(contact)
    end
  end

  describe "#accept" do
    let(:unkown_phone) { "7890476" }
    let(:phone) { "465789" }

    it "should noop for unkown numbers" do
      subject.accept(unkown_phone, "lorem ipsum")
    end

    it "should use contact within surveys_ongoing_or_stalled" do
      allow(channel).to receive(:send_sms)

      old_contact = Contact.create!(phone: phone, tracking_status: 'sms_info', language: 'en', clinic1: clinic1, clinic2: clinic2)
      subject.start_survey(old_contact)
      subject.accept phone, "yes"

      new_contact = Contact.create!(phone: phone, tracking_status: 'sms_info', language: 'en', clinic1: clinic1, clinic2: clinic2)
      subject.start_survey(new_contact)
      subject.accept phone, "no"

      old_contact.reload
      new_contact.reload

      expect(old_contact.survey_was_seen).to eq(true)
      expect(new_contact.survey_was_seen).to eq(false)
    end

    it "should fail if there are multiple active contacts (invariant broken)" do
      allow(channel).to receive(:send_sms)

      old_contact = Contact.create!(phone: phone, tracking_status: 'sms_info', survey_status: 'pending_seen', language: 'en', clinic1: clinic1, clinic2: clinic2)
      new_contact = Contact.create!(phone: phone, tracking_status: 'sms_info', survey_status: 'pending_seen', language: 'en', clinic1: clinic1, clinic2: clinic2)

      expect {
        subject.accept phone, "yes"
      }.to raise_error("Multiple active surveys for phone: #{phone}.")
    end
  end

  describe "survey tracking" do
    let!(:phone)   { "465789" }
    let!(:contact) { Contact.create!(phone: phone, tracking_status: 'sms_info', language: 'en', clinic1: clinic1, clinic2: clinic2) }

    it "should track responses (seen)" do
      allow(channel).to receive(:send_sms)

      subject.start_survey(contact)
      subject.accept phone, "yes"
      subject.accept phone, "2"
      subject.accept phone, "5"
      subject.accept phone, "no"

      contact = Contact.find_by(phone: phone)
      expect(contact.survey_was_seen).to eq(true)
      expect(contact.survey_chosen_clinic_id).to eq(clinic2.id)
      expect(contact.survey_clinic_rating).to eq(5)
      expect(contact.survey_can_be_called).to eq(false)
    end

    it "should track responses (rejected)" do
      allow(channel).to receive(:send_sms)

      subject.start_survey(contact)
      subject.accept phone, "no"
      subject.accept phone, "4"
      subject.accept phone, "1"
      subject.accept phone, "yes"

      contact = Contact.find_by(phone: phone)
      expect(contact.survey_was_seen).to eq(false)
      expect(contact.survey_chosen_clinic_id).to eq(clinic1.id)
      expect(contact.survey_reason_not_seen).to eq("rejected")
      expect(contact.survey_can_be_called).to eq(true)
    end

    it "should track responses (cost)" do
      allow(channel).to receive(:send_sms)

      subject.start_survey(contact)
      subject.accept phone, "no"
      subject.accept phone, "3"
      subject.accept phone, "yes"

      contact = Contact.find_by(phone: phone)
      expect(contact.survey_was_seen).to eq(false)
      expect(contact.survey_chosen_clinic_id).to be_nil
      expect(contact.survey_reason_not_seen).to eq("cost")
      expect(contact.survey_can_be_called).to eq(true)
    end

  end

  describe "survey answers" do
    let(:contact) { Contact.create!(phone: "465789", tracking_status: 'sms_info', language: 'en', clinic1: clinic1, clinic2: clinic2) }

    it "should send answers via channel" do
      expect(channel).to receive(:send_sms).with(contact.phone, I18n.t('survey.start_message', locale: 'en'))
      subject.start_survey(contact)

      expect(channel).to receive(:send_sms).with(contact.phone, "#{I18n.t('survey.which_clinic_did_you_choose', locale: 'en')} Please reply with '1' for Name 1, '2' for Name 2")
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
      subject.start_survey(contact)

      expect(channel).to receive(:send_sms).with(contact.phone, "#{I18n.t('survey.which_clinic_did_you_choose', locale: 'es')} Por favor conteste con '1' para Name 1, '2' para Name 2")
      subject.accept contact.phone, "yes"

      expect(channel).to receive(:send_sms).with(contact.phone, "#{I18n.t('survey.ask_satisfaction', locale: 'es')}")
      subject.accept contact.phone, "2"

      expect(channel).to receive(:send_sms).with(contact.phone, "#{I18n.t('survey.can_we_call_later', locale: 'es')}")
      subject.accept contact.phone, "5"

      expect(channel).to receive(:send_sms).with(contact.phone, "#{I18n.t('survey.thanks', locale: 'es')}")
      subject.accept contact.phone, "no"
    end
  end

  describe "side effects" do
    let!(:contact) { Contact.create!(phone: "9991000", tracking_status: 'sms_info', language: 'en', clinic1: clinic1, clinic2: clinic2) }

    it "should set first rating for clinic" do
      allow(channel).to receive(:send_sms)

      phone = contact.phone
      subject.start_survey(contact)
      subject.accept phone, "yes"
      subject.accept phone, "2"
      subject.accept phone, "4"
      subject.accept phone, "no"

      expect(clinic2.reload.avg_rating).to eq(4)
      expect(clinic2.rated_times).to eq(1)
    end

    it "should update rating for clinic" do
      clinic2.update_attributes!(avg_rating: 3.5, rated_times: 6)
      allow(channel).to receive(:send_sms)

      phone = contact.phone
      subject.start_survey(contact)
      subject.accept phone, "yes"
      subject.accept phone, "2"
      subject.accept phone, "4"
      subject.accept phone, "no"

      expect(clinic2.reload.avg_rating).to be_within(0.001).of((3.5 * 6 + 4) / 7)
      expect(clinic2.rated_times).to eq(7)
    end
  end
end
