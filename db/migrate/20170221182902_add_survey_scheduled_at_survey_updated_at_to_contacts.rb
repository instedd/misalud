class AddSurveyScheduledAtSurveyUpdatedAtToContacts < ActiveRecord::Migration[5.0]
  def change
    add_column :contacts, :survey_scheduled_at, :datetime
    add_column :contacts, :survey_updated_at, :datetime
  end
end
