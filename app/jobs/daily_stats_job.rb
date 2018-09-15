class DailyStatsJob < ApplicationJob
  queue_as :default

  def perform
    ApplicationRecord.daily_reload!
  end

end
