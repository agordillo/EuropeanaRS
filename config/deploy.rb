# Call this script with the following syntax:
# bundle exec cap deploy DEPLOY=myEnvironment
# Where myEnvironment is the name of the xml file (config/deploy/myEnvironment.xml) which defines the deployment.

require 'yaml'
require "bundler/capistrano"

begin
  config = YAML.load_file(File.expand_path('../deploy/' + ENV['DEPLOY'] + '.yml', __FILE__))
  puts config["message"] unless config["message"].nil?
  repository = config["repository"]
  server_url = config["server_url"]
  username = config["username"]
  keys = config["keys"]
  branch = config["branch"] || "master"
rescue Exception => e
  # puts e.message
  puts "Sorry, the file config/deploy/" + ENV['DEPLOY'] + '.yml does not exist.'
  exit
end

# Where we get the app from and all...
set :scm, :git
set :repository, repository

puts "Using branch: '" + branch + "'"
set :branch, fetch(:branch, branch)

# Some options
default_run_options[:pty] = true
ssh_options[:forward_agent] = true
ssh_options[:keys] = keys if keys

# Servers to deploy to
set :application, "europeanars"
set :user, username

role :web, server_url # Your HTTP server, Apache/etc
role :app, server_url # This may be the same as your `Web` server
role :db,  server_url, :primary => true # This is where Rails migrations will run

after 'deploy:update_code', 'deploy:fix_file_permissions'
before 'deploy:precompile_europeanars_assets', 'deploy:link_files'
after "deploy:fix_file_permissions", "deploy:precompile_europeanars_assets"
after 'deploy:precompile_europeanars_assets', 'deploy:static_assets'
before 'deploy:restart', 'deploy:start_sphinx'
after  'deploy:start_sphinx', 'deploy:fix_sphinx_file_permissions'
after "deploy:restart", "deploy:cleanup"


namespace(:deploy) do
  # Tasks for passenger mod_rails
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  task :fix_file_permissions do
    # LOG
    run "#{try_sudo} touch #{release_path}/log/production.log"
    run "#{try_sudo} /bin/chmod 666 #{release_path}/log/production.log"
  end

  task :link_files do
    run "ln -s #{shared_path}/database.yml #{release_path}/config/database.yml"
    run "ln -s #{shared_path}/application_config.yml #{release_path}/config/application_config.yml"
    run "ln -s #{shared_path}/thinking_sphinx.yml #{release_path}/config/thinking_sphinx.yml"
  end

  task :precompile_europeanars_assets do
    run "cd #{release_path} && bundle exec \"rake assets:precompile --trace RAILS_ENV=production\""
  end

  task :static_assets do
    run "cp -r #{release_path}/app/assets/images/* #{release_path}/public/assets/"
    run "cp -r #{release_path}/app/assets/fonts/* #{release_path}/public/assets/"
  end

  task :start_sphinx do
    run "cd #{current_path} && kill -9 `cat log/production.sphinx.pid` || true"
    run "cd #{release_path} && bundle exec \"rake ts:rebuild RAILS_ENV=production\""
  end

  task :fix_sphinx_file_permissions do
    run "/bin/chmod g+rw #{release_path}/log/production.searchd*"
    sudo "/bin/chgrp www-data #{release_path}/log/production.searchd*"
  end

end