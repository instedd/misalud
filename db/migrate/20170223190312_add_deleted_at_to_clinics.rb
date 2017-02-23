class AddDeletedAtToClinics < ActiveRecord::Migration[5.0]
  def change
    add_column :clinics, :deleted_at, :datetime
    add_index :clinics, :deleted_at
  end
end
