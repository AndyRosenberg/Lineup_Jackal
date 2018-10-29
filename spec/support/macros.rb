require 'rails_helper'

def add_user
  let(:andy) { Fabricate(:user) }
end

def add_lineup
  let(:my_lineup) { Fabricate(:lineup) }
end

def assign_lineup(user, lineup)
  lineup.user_id = user.id
  lineup.save!
end

def add_5_players(lineup)
  5.times do
    pl = Fabricate(:player)
    pl.lineup_id = lineup.id
    pl.save!
    lineup.players << pl
  end
end

def add_session
  add_user
  session[:user_id] = andy.id
end
