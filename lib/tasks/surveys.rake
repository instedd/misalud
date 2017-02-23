namespace :surveys do
  desc "Start a surver worker process"
  task worker: :environment do
    puts Rails.env
    while true
      print "#{Time.now.utc}: Started "
      print SurveyScheduler.run
      puts " surveys."
      sleep(30.seconds)
    end
  end
end
