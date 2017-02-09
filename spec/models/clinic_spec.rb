require 'rails_helper'

RSpec.describe Clinic, type: :model do
  describe ".import_clinic" do
    it "should create new record" do
      expect {
        Clinic.import_clinic 48, {
          "name" => "Lorem Ipsum",
          "short_name" => "LorIp",
          "address" => "Place",
          "schedule" => "Mon-Sun 8:00-17:00",
          "walkin_schedule" => "Mon-Fri 12:00-14:00",
        }
      }.to change(Clinic, :count).by(1)

      clinic = Clinic.find_by(resmap_id: 48)

      expect(clinic.name).to eq("Lorem Ipsum")
      expect(clinic.short_name).to eq("LorIp")
      expect(clinic.address).to eq("Place")
      expect(clinic.schedule).to eq("Mon-Sun 8:00-17:00")
      expect(clinic.walkin_schedule).to eq("Mon-Fri 12:00-14:00")
      expect(clinic.selected_times).to eq(0)
    end

    it "should update record based on resmap_id and do not touch other fields" do
      Clinic.import_clinic 48, {
        "name" => "Lorem Ipsum",
      }
      Clinic.find_by(resmap_id: 48).update_attributes!(selected_times: 7)

      expect {
        Clinic.import_clinic 48, {
          "name" => "Lorem Ipsum (updated)",
        }
      }.to change(Clinic, :count).by(0)

      clinic = Clinic.find_by(resmap_id: 48)

      expect(clinic.name).to eq("Lorem Ipsum (updated)")
      expect(clinic.selected_times).to eq(7)
    end
  end

  describe '.pick' do
    before(:each) do
      (1..20).each do |i|
        Clinic.import_clinic i, {"name" => "Name #{i}"}
      end
    end

    it "should add to selected_clinic count" do
      expect(Clinic.sum('selected_times')).to eq(0)
      clinics = Clinic.pick
      expect(clinics.size).to eq(3)
      expect(Clinic.where(id: clinics.map(&:id)).sum('selected_times')).to eq(3)
    end

    it "should return eventually all clinics" do
      (Clinic.count * 3).times { Clinic.pick }
      expect(Clinic.where(selected_times: 0).count).to eq(0)
    end
  end

  describe '.pick with small amount of clinics' do
    before(:each) do
      (1..2).each do |i|
        Clinic.import_clinic i, {"name" => "Name #{i}"}
      end
    end

    it "should add to selected_clinic count" do
      expect(Clinic.sum('selected_times')).to eq(0)
      clinics = Clinic.pick
      expect(clinics.size).to eq(2)
      expect(Clinic.where(id: clinics.map(&:id)).sum('selected_times')).to eq(2)
    end
  end
end
