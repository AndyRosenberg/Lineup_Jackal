require 'rails_helper'
require 'spec_helper'

describe Player do
  let(:luck) { Player.fake(Statistic.find_player('1932')) }

  describe "::fake" do
    it "returns Andrew Luck player object" do
      expect(luck.full_name).to be == "Andrew Luck"
    end
  end

  describe "::fake_show" do
    let(:fake_luck) { Player.fake_show(JSON.parse(luck.to_json)) }

    it "returns player object from hash" do
      expect(fake_luck.class.name).to be == "Player"
    end

    it "still returns Andrew Luck" do
      expect(fake_luck.full_name).to be == "Andrew Luck"
    end
  end
end