class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.total_reload!
    ActiveRecord::Base.transaction do
      players!
      draft!
      injuries!
      schedules!
      weekly_proj!
      last_5!
      prev_weeks!
      everything!
    end
  end

  def self.daily_reload!
    players!
    draft!
    injuries!
    schedules!
    weekly_proj!
    everything!
  end

  def self.weekly_reload!
    prev_weeks!
    everything!
  end

  def self.yearly_reload!
    last_5!
    everything!
  end

  private
  def self.stat(stat_name)
    Statistic.find_or_create_by(name: stat_name)
  end

  def self.everything!
    everything = stat("everything")
    everything.update!(json: JSON.generate(Statistic.create_everything))
  end

  def self.prev_weeks!
    prev_weeks = stat("prev_weeks")
    prev_weeks.update!(json: JSON.generate(Statistic.prev_weeks))
  end
  
  def self.last_5!
    last_5 = stat("last_5")
    last_5.update!(json: JSON.generate(Statistic.prev_n_years(5)))
  end

  def self.weekly_proj!
    positions = ['QB', 'RB', 'WR', 'TE', 'K', 'DEF']
    weekly = {}
      positions.each do |pos|
        weekly[pos] = FFNerd.weekly_rankings(pos).map(&:to_h)
      end
    past_weekly = stat("weekly")
    past_weekly.update!(json: JSON.generate(weekly), week: CURRENT_WEEK)
  end
  
  def self.schedules!
    schedules = FFNerd.schedule.map(&:to_h)
    past_schedules = stat("schedules")
    past_schedules.update!(json: JSON.generate(schedules))
  end

  def self.injuries!
    current_injuries = FFNerd.injuries.map(&:to_h).select { |pl| pl[:player_id] && pl[:player_id] != "0" }
    past_injuries = stat("injuries")
    past_injuries.update!(json: JSON.generate(current_injuries))
  end

  def draft!
    rankings = {}
    positions = ['QB', 'RB', 'WR', 'TE', 'K', 'DEF']

    positions.each do |pos|
      rankings[pos] = FFNerd.draft_projections(pos).map(&:to_h)
    end

    draft = stat("draft")
    draft.update!(json: JSON.generate(rankings))
  end

  def self.players!
    all_players = JSON.generate(FFNerd.players.map(&:to_h))
    players = stat("players")
    players.update!(json: all_players)
  end

end
