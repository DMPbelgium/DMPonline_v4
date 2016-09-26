#!/bin/bash
#
# This script will install the needed gem requirements for the DMPonline application
export RAILS_ENV=production

source "/usr/local/rvm/scripts/rvm" &&
cd /opt/DMPonline_v4 &&
gem install bundler &&
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

#temporary hack: set shibboleth_id of old users to email
#bundle exec rake dmponline:user_setup_shibboleth
