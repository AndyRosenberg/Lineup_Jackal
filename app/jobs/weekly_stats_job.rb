class WeeklyStatsJob < ApplicationJob
  queue_as :default

  before_perform do |job|
    weekly = {}
    positions = ['QB', 'RB', 'WR', 'TE', 'K', 'DEF']
    positions.each do |pos|
      weekly[pos] = FFNerd.weekly_rankings(pos).map(&:to_h)
    end

    old_weekly = Statistic.find_by(name: "weekly") 
    old_weekly.update!(json: JSON.generate(weekly))

    current_injuries = FFNerd.injuries.map(&:to_h).select { |pl| pl[:player_id] && pl[:player_id] != "0" }
    past_injuries = Statistic.find_or_create_by(name: "injuries")
    past_injuries.update!(json: JSON.generate(current_injuries))
  end

  def perform(everything = "everything")
    old_everything = Statistic.find_by(name: everything)
    old_everything.update!(json: JSON.generate(Statistic.create_everything))
  end

end
