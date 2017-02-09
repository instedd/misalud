class CreateClinics < ActiveRecord::Migration[5.0]
  def change
    create_table :clinics do |t|
      t.integer :resmap_id
      t.string :name
      t.string :short_name
      t.string :address
      t.string :schedule
      t.string :walkin_schedule

      t.timestamps
    end
  end
end
