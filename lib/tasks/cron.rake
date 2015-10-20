namespace :cron do
  desc "Hourly tasks"
  task :hourly => []
  desc "Daily tasks"
  task :daily  => [ "context:clearExpiredSessions", "context:updatePopularityMetrics" ]
  desc "Weekly tasks"
  task :weekly => [ "context:updateWordsFrequency" ]
  desc "Monthly tasks"
  task :monthly => []
end