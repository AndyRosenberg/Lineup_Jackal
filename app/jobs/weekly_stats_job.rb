class WeeklyStatsJob < ApplicationJob
  queue_as :default

  def perform
    ApplicationRecord.total_reload!
  end

end
