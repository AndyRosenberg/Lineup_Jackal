class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.total_reload!
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

    weekly = {}
    positions.each do |pos|
      weekly[pos] = FFNerd.weekly_rankings(pos).map(&:to_h)
    end

    past_weekly = Statistic.find_or_create_by(name: "weekly")
    past_weekly.update(json: JSON.generate(weekly), week: CURRENT_WEEK)

    last_5 = Statistic.find_or_create_by(name: "last_5")
    last_5.update(json: JSON.generate(Statistic.prev_n_years(5)))

    prev_weeks = Statistic.find_or_create_by(name: "prev_weeks")
    prev_weeks.update(json: JSON.generate(Statistic.prev_weeks))

    imgs = Statistic.find_or_create_by(name: "images")
    images = Statistic.active_players.map {|plyr| {plyr["player_id"] => Statistic.find_image(plyr["display_name"])} }.select{|pl| !pl.values.first.nil?}
    imgs.update(json: JSON.generate(images))

    everything = Statistic.find_or_create_by(name: "everything")
    everything.update(json: JSON.generate(Statistic.create_everything))

    standard = Statistic.find_or_create_by(name: "standard")
    standard.update(json: JSON.generate(Statistic.create_stats("standard")))

    ppr = Statistic.find_or_create_by(name: "ppr")
    ppr.update(json: JSON.generate(Statistic.create_stats("ppr")))
  end
end
