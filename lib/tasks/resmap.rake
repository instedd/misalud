namespace :resmap do
  desc "Imports or reimports all clinics from configured Resmap collection"
  task import: :environment do
    sites = Clinic.import
    puts "Imported #{sites.size} sites(s) from Resmap collection #{Settings.resmap.collection_id}"
  end
end
