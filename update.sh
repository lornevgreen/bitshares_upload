#!/bin/bash
cd code
git pull
bundle install --deployment --without development test
bundle exec rake assets:precompile db:migrate RAILS_ENV=production
cd ..
passenger-config restart-app $(pwd)
sudo service nginx restart
