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

  def perform(everything = "everything", standard = "standard", ppr = "ppr")
    old_everything = Statistic.find_by(name: everything)
    old_standard = Statistic.find_by(name: standard)
    old_ppr = Statistic.find_by(name: ppr)

    old_everything.update!(json: JSON.generate(Statistic.create_everything))

    old_standard.update!(json: JSON.generate(Statistic.update_weeks('standard')))

    old_ppr.update!(json: JSON.generate(Statistic.update_weeks('ppr')))
  end

end
