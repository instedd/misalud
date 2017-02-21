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
end
