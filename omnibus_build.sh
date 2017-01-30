#!/bin/bash -e

###########################
#
# WARNING: You need to rebuild the docker images if you do any changes to this file
#
############################

PROJECT_DIR=dd-agent-omnibus
PROJECT_NAME=datadog-agent
LOG_LEVEL=${LOG_LEVEL:-"info"}
export OMNIBUS_BRANCH=${OMNIBUS_BRANCH:-"master"}
export OMNIBUS_SOFTWARE_BRANCH=${OMNIBUS_SOFTWARE_BRANCH:-"master"}
export OMNIBUS_RUBY_BRANCH=${OMNIBUS_RUBY_BRANCH:-"datadog-5.5.0"}
export INTEGRATION_CORE_BRANCH=${INTEGRATION_CORE_BRANCH:-"master"}
export USE_INTEGRATION_SDK=${USE_INTEGRATION_SDK:-""}

set -e

# Clean up omnibus artifacts
rm -rf /var/cache/omnibus/pkg/*

# Clean up what we installed
rm -f /etc/init.d/datadog-agent
rm -rf /etc/dd-agent
rm -rf /opt/$PROJECT_NAME/*

builtin cd $PROJECT_DIR

# Allow to use a different dd-agent-omnibus branch
git fetch --all
git checkout $OMNIBUS_BRANCH
git reset --hard origin/$OMNIBUS_BRANCH

# If an RPM_SIGNING_PASSPHRASE has been passed, let's import the signing key
if [ -n "$RPM_SIGNING_PASSPHRASE" ]; then
  gpg --import /keys/RPM-SIGNING-KEY.private
fi

# Install the gems we need, with stubs in bin/
bundle update # Make sure to update to the latest version of omnibus-software
bin/omnibus build -l=$LOG_LEVEL $PROJECT_NAME
