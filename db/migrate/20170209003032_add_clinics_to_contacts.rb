class AddClinicsToContacts < ActiveRecord::Migration[5.0]
  def change
    add_reference :contacts, :clinic1, foreign_key: { to_table: :clinics }
    add_reference :contacts, :clinic2, foreign_key: { to_table: :clinics }
    add_reference :contacts, :clinic3, foreign_key: { to_table: :clinics }
  end
end
