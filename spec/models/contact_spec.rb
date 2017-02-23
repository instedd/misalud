require 'rails_helper'

RSpec.describe Contact, type: :model do
  describe '#pick_clinics' do
    let(:contact) { Contact.create! tracking_status: 'call_started' }

    context 'with many clinics' do
      before(:each) do
        (1..20).each do |i|
          Clinic.import_clinic i, {"name" => "Name #{i}"}
        end
      end

      it "should assign clinics" do
        contact.pick_clinics
        contact.reload
        expect(contact.clinics.size).to eq(3)
      end
    end


    context 'with few clinics' do
      before(:each) do
        (1..2).each do |i|
          Clinic.import_clinic i, {"name" => "Name #{i}"}
        end
      end

      it "should be able to assign less than 3 clinics" do
        contact.pick_clinics
        contact.reload
        expect(contact.clinics.size).to eq(2)
      end
    end
  end

  describe "#schedule_survey!" do
    let(:contact) { Contact.create! tracking_status: 'sms_info' }

    it "should schedule in a week for pregnant" do
      contact.pregnant = true
      contact.save!
      contact.schedule_survey!
      expect(contact.survey_scheduled_at).to be_within(1.minute).of(Time.now.utc + 1.week)
    end

    it "should schedule in a week for urgent" do
      contact.pregnant = false
      contact.urgent = true
      contact.save!
      contact.schedule_survey!
      expect(contact.survey_scheduled_at).to be_within(1.minute).of(Time.now.utc + 1.week)
    end

    it "should schedule in a month for non urgent" do
      contact.pregnant = false
      contact.urgent = false
      contact.save!
      contact.schedule_survey!
      expect(contact.survey_scheduled_at).to be_within(1.minute).of(Time.now.utc + 1.month)
    end
  end

  describe ".survey_ready_to_start" do
    around(:each) do |example|
      Timecop.freeze(Time.now)
      example.run
      Timecop.return
    end

    it "should be ready after the survey_scheduled_at and up to 15 min later" do
      Contact.create! tracking_status: 'sms_info', survey_scheduled_at: Time.now.utc + 1.week

      1.days.later
      expect(Contact.survey_ready_to_start).to be_empty

      6.days.later
      expect(Contact.survey_ready_to_start).to_not be_empty

      5.minutes.later
      expect(Contact.survey_ready_to_start).to_not be_empty

      15.minutes.later
      expect(Contact.survey_ready_to_start).to be_empty

      (23.hours + 40.minutes).later
      expect(Contact.survey_ready_to_start).to_not be_empty

      20.minutes.later
      expect(Contact.survey_ready_to_start).to be_empty
    end
  end
end
