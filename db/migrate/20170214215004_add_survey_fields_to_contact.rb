class AddSurveyFieldsToContact < ActiveRecord::Migration[5.0]
  def change
    add_column :contacts, :survey_was_seen, :boolean
    add_column :contacts, :survey_chosen_clinic_id, :integer
    add_column :contacts, :survey_clinic_rating, :integer
    add_column :contacts, :survey_can_be_called, :boolean
    add_column :contacts, :survey_reason_not_seen, :string
    remove_column :contacts, :survey_data, :text
  end
end
