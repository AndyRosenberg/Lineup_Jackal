require 'rails_helper'
require 'spec_helper'

describe Statistic do
  describe "::everything" do
    let(:result) { Statistic.everything }

    it "sorts by projected" do
      res1, res2, res3 = result[0]['projected'].to_i, result[1]['projected'].to_i, result[2]['projected'].to_i
      expect(res1).to be >= res2 
      expect(res1).to be >= res3 
      expect(res2).to be >= res3 
    end

    it "has correct ffn properties" do
      first = result.first
      expect(first['ff_id']).to be
      expect(first['full_name']).to be
      expect(first['team']).to be
      expect(first['schedule']).to be
      expect(first['injuries']).to be
      expect(first['projected']).to be
      expect(first['weekly_standard']).to be
      expect(first['weekly_ppr']).to be
    end
  end
end