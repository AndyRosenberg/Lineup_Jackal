class WeeklyStatsJob < ApplicationJob
  queue_as :default

  def perform
    ApplicationRecord.weekly_reload!
  end

end
