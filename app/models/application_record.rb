class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.total_reload!
    ActiveRecord::Base.transaction do
      all_players = JSON.generate(FFNerd.players.map(&:to_h))
      players = Statistic.find_or_create_by(name: "players")
      players.update!(json: all_players)

      rankings = {}
      positions = ['QB', 'RB', 'WR', 'TE', 'K', 'DEF']

      positions.each do |pos|
        rankings[pos] = FFNerd.draft_projections(pos).map(&:to_h)
      end

      draft = Statistic.find_or_create_by(name: "draft")
      draft.update!(json: JSON.generate(rankings))

      weekly = {}
      positions.each do |pos|
        weekly[pos] = FFNerd.weekly_rankings(pos).map(&:to_h)
      end

      current_injuries = FFNerd.injuries.map(&:to_h).select { |pl| pl[:player_id] && pl[:player_id] != "0" }
      past_injuries = Statistic.find_or_create_by(name: "injuries")
      past_injuries.update!(json: JSON.generate(current_injuries))

      schedules = FFNerd.schedule.map(&:to_h)
      past_schedules = Statistic.find_or_create_by(name: "schedules")
      past_schedules.update!(json: JSON.generate(schedules))

      past_weekly = Statistic.find_or_create_by(name: "weekly")
      past_weekly.update!(json: JSON.generate(weekly), week: CURRENT_WEEK)

      last_5 = Statistic.find_or_create_by(name: "last_5")
      last_5.update!(json: JSON.generate(Statistic.prev_n_years(5)))

      prev_weeks = Statistic.find_or_create_by(name: "prev_weeks")
      prev_weeks.update!(json: JSON.generate(Statistic.prev_weeks))

      everything = Statistic.find_or_create_by(name: "everything")
      everything.update!(json: JSON.generate(Statistic.create_everything))
    end
  end

end
