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
  end

  def perform(everything = "everything")
    old_everything = Statistic.find_by(name: everything)
    old_everything.update!(json: JSON.generate(Statistic.create_everything))
  end

end
