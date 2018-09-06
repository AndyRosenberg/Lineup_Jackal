class AddTokenToLineups < ActiveRecord::Migration[5.2]
  def change
    add_column :lineups, :token, :string
  end
end
