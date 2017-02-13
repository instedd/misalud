class AddTrackingStatusToContacts < ActiveRecord::Migration[5.0]
  def change
    add_column :contacts, :tracking_status, :string
    add_column :contacts, :call_started_at, :datetime
  end
end
