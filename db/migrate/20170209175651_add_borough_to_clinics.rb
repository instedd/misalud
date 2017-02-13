class AddBoroughToClinics < ActiveRecord::Migration[5.0]
  def change
    add_column :clinics, :borough, :string
  end
end
