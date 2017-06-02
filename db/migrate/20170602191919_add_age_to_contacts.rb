class AddAgeToContacts < ActiveRecord::Migration[5.0]
  def change
    add_column :contacts, :age, :integer
  end
end
