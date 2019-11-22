#!/bin/bash
#
# This script will install the needed gem requirements for the DMPonline application

#as of januari 2019, bundler has stopped supporting ruby < 2.3
#so please install bundler from 2018

cd /opt/DMPonline_v4 &&
. env.sh &&
gem install bundler --version="1.17.3" &&
bundle install --deployment &&
bundle exec rake db:migrate &&
#sprocket cache hanging around for no good reason
rm -rf tmp/cache/* &&
bundle exec rake assets:precompile &&
touch tmp/restart.txt

# Generate .assets-version file
if [ ! -f .assets-version ]; then
  touch .assets-version
fi
VERSION=`cat .assets-version`
VERSION=`expr $VERSION + 1`
echo -n $VERSION > .assets-version
