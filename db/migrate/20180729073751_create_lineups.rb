class CreateLineups < ActiveRecord::Migration[5.2]
  def change
    create_table :lineups do |t|
      t.string :name
      t.string :league_type, default: 'standard'
      t.integer :user_id
      t.timestamps
    end
  end
end
