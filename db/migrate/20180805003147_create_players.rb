class CreatePlayers < ActiveRecord::Migration[5.2]
  def change
    create_table :players do |t|
      t.integer :lineup_id
      t.string :status
      t.string :ff_id
      t.string :full_name
      t.string :position
    end
  end
end
