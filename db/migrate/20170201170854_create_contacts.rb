class CreateContacts < ActiveRecord::Migration[5.0]
  def change
    create_table :contacts do |t|
      t.string :phone
      t.string :survey_status
      t.text :survey_data

      t.timestamps
    end
  end
end
