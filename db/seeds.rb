# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

FFNerd.api_key = FFN_KEY

all_players = JSON.generate(FFNerd.players.map(&:to_h))
players = Statistic.find_or_create_by(name: "players")
players.update(json: all_players)

rankings = {}
positions = ['QB', 'RB', 'WR', 'TE', 'K', 'DEF']

positions.each do |pos|
  rankings[pos] = FFNerd.draft_projections(pos).map(&:to_h)
end

draft = Statistic.find_or_create_by(name: "draft")
draft.update(json: JSON.generate(rankings))

if !Statistic.find_by(name: "weekly")
  weekly = {}
  positions.each do |pos|
    weekly[pos] = FFNerd.weekly_rankings(pos).map(&:to_h)
  end
  Statistic.create(name: "weekly", json: JSON.generate(weekly), week: CURRENT_WEEK)
end

last_5 = Statistic.find_or_create_by(name: "last_5")
last_5.update(json: JSON.generate(Statistic.prev_n_years(5)))

prev_weeks = Statistic.find_or_create_by(name: "prev_weeks")
prev_weeks.update(json: JSON.generate(Statistic.prev_weeks))

imgs = Statistic.find_by(name: "images")

if !imgs
  images = Statistic.active_players.map {|plyr| {plyr["player_id"] => Statistic.find_image(plyr["display_name"])} }.select{|pl| !pl.values.first.nil?}
  imgs = Statistic.create(name: "images")
  imgs.update(json: JSON.generate(images))
end

everything = Statistic.find_or_create_by(name: "everything")
everything.update(json: JSON.generate(Statistic.create_everything))

standard = Statistic.find_or_create_by(name: "standard")
standard.update(json: JSON.generate(Statistic.create_stats("standard")))

ppr = Statistic.find_or_create_by(name: "ppr")
ppr.update(json: JSON.generate(Statistic.create_stats("ppr")))
