class AddCallSidToContacts < ActiveRecord::Migration[5.0]
  def change
    add_column :contacts, :call_sid, :string
  end
end
