namespace :cron do
  desc "Hourly tasks"
  task :hourly => []
  desc "Daily tasks"
  task :daily  => [ "context:updatePopularityMetrics" ]
  desc "Weekly tasks"
  task :weekly => []
  desc "Monthly tasks"
  task :monthly => []
end