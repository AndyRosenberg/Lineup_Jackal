require 'rails_helper'

describe Lineup do
  add_lineup

  context '5 players' do
    before do
      add_5_players(my_lineup)
    end

    it 'has 5 players' do
      expect(my_lineup.players.length).to eq(5)
    end

    describe '#bench' do
       it 'also has 5' do
         expect(my_lineup.bench.size).to eq(5)
       end
    end
  end
end