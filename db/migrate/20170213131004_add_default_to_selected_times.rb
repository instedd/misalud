class AddDefaultToSelectedTimes < ActiveRecord::Migration[5.0]
  def up
    change_column :clinics, :selected_times, :integer, default: 0, null: false
  end

  def down
    change_column :clinics, :selected_times, :integer, default: nil, null: true
  end
end
