#!/bin/bash -e

###########################
#
# WARNING: You need to rebuild the docker images if you do any changes to this file
#
############################

PROJECT_DIR=dd-agent-omnibus
PROJECT_NAME=datadog-agent
LOG_LEVEL=${LOG_LEVEL:-"debug"}
OMNIBUS_BRANCH=${OMNIBUS_BRANCH:-"master"}
OMNIBUS_SOFTWARE_BRANCH=${AGENT_BRANCH:-"master"}

# Clean up omnibus artifacts
rm -rf /var/cache/omnibus/pkg/*

# Clean up what we installed
rm -f /etc/init.d/datadog-agent
rm -rf /etc/dd-agent
rm -rf /opt/$PROJECT_NAME/*

cd $PROJECT_DIR
# Allow to use a different dd-agent-omnibus branch
git fetch --all
git checkout $OMNIBUS_BRANCH
git reset --hard origin/$OMNIBUS_BRANCH

# Install the gems we need, with stubs in bin/
bundle update # Make sure to update to the latest version of omnibus-software
bin/omnibus build -l="debug" $PROJECT_NAME
