require 'rails_helper'

RSpec.describe Contact, type: :model do
  describe '#pick_clinics' do
    let(:contact) { Contact.create! }

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
end
