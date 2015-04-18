#!/bin/bash -e
PROJECT_DIR=dd-agent-omnibus
PROJECT_NAME=datadog-agent
${LOG_LEVEL:=info}

# Clean up omnibus artifacts
rm -rf /var/cache/omnibus/pkg/*

# Clean up what we installed
rm -f /etc/init.d/datadog-agent
rm -rf /etc/dd-agent
rm -rf /opt/$PROJECT_NAME/*

cd $PROJECT_DIR
# Install the gems we need, with stubs in bin/
bundle update # Make sure to update to the latest version of omnibus-software
bin/omnibus build -l=$LOG_LEVEL $PROJECT_NAME
