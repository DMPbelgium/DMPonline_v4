#!/bin/bash
#
export PATH="$PATH:/usr/local/rvm/bin"
export RAILS_ENV=production

source "/usr/local/rvm/scripts/rvm" &&
gem install bundler &&
bundle install --deployment &&
bundle exec rake assets:precompile &&
bundle exec rake db:migrate &&
touch tmp/restart.txt
