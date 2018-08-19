class WeeklyStatsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    weekly = {}
    positions.each do |pos|
      weekly[pos] = FFNerd.weekly_rankings(pos).map(&:to_h)
    end

    new_week = Statistic.find_by(name: "weekly") 
    new_week.update!(json: JSON.generate(weekly))

    everything = Statistic.find_by(name: "everything")
    everything.update!(json: JSON.generate(Statistic.create_everything))

    Statistic.update_standard_weeks!
    Statistic.update_ppr_weeks!
  end

end
