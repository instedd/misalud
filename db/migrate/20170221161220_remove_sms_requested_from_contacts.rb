class RemoveSmsRequestedFromContacts < ActiveRecord::Migration[5.0]
  def change
    remove_column :contacts, :sms_requested, :boolean
  end
end
