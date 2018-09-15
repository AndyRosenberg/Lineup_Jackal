class YearlyStatsJob < ApplicationJob
  queue_as :default

  def perform
    ApplicationRecord.yearly_reload!
  end

end
