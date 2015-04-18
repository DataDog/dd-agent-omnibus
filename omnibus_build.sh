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
/bin/bash -l -c "git pull"
/bin/bash -l -c "rvm use 2.2.2"
/bin/bash -l -c "bundle update" # Make sure to update to the latest version of omnibus-software
/bin/bash -l -c "bin/omnibus build -l=$LOG_LEVEL $PROJECT_NAME"
