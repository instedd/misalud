class SurveyScheduler
  def self.run
    message_processor = MessageProcessor.new(SmsChannel.build)
    Contact.survey_ready_to_start.each do |contact|
      message_processor.start_survey(contact) rescue nil
    end.count
  end
end
