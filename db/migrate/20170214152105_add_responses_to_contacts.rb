class AddResponsesToContacts < ActiveRecord::Migration[5.0]
  def change
    add_column :contacts, :pregnant, :boolean
    add_column :contacts, :urgent, :boolean
    add_column :contacts, :known_condition, :boolean
    add_column :contacts, :borough, :string
    add_column :contacts, :language, :string
    add_column :contacts, :sms_requested, :boolean
  end
end
