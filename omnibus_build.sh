#!/bin/bash -e

###########################
#
# WARNING: You need to rebuild the docker images if you do any changes to this file
#
############################

PROJECT_DIR=dd-agent-omnibus
PROJECT_NAME=datadog-agent
LOG_LEVEL=${LOG_LEVEL:-"info"}
JMX_VERSION=${JMX_BRANCH:-"current"}
export AGENT_BRANCH=${AGENT_BRANCH:-"master"}
export OMNIBUS_BRANCH=${OMNIBUS_BRANCH:-"master"}
export OMNIBUS_SOFTWARE_BRANCH=${OMNIBUS_SOFTWARE_BRANCH:-"master"}
export OMNIBUS_RUBY_BRANCH=${OMNIBUS_RUBY_BRANCH:-"datadog-5.5.0"}
export INTEGRATION_CORE_BRANCH=${INTEGRATION_CORE_BRANCH:-"master"}

REMOTE_AGENT_REPO_RAW="https://raw.githubusercontent.com/DataDog/dd-agent"
LOCAL_DD_AGENT="/dd-agent-repo"

unset_jmx() {
    echo "JMX provided by dd-agent in selected branch, JMX environment variables will be ignored."
    unset JMX_VERSION
    unset JMX_BRANCH
}

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

# If "current" JMX version, set it from the corresponding agent branch config.py
if [ "$JMX_VERSION" == "current" ]; then
  if [ -n "$LOCAL_AGENT_REPO" ]; then
    cd $LOCAL_DD_AGENT
    JMX_VERSION=$(git show $AGENT_BRANCH:config.py | grep 'JMX_VERSION' | cut -f2 -d'=' | tr -d ' "')
    cd -
  else
    JMX_VERSION=$(curl -v $REMOTE_AGENT_REPO_RAW/$AGENT_BRANCH/config.py 2>/dev/null | grep 'JMX_VERSION' | cut -f2 -d'=' | tr -d ' "')
  fi

  if [ -n "$JMX_VERSION" ]; then
    export JMX_VERSION=$JMX_VERSION
  else
    unset_jmx
  fi
else
  if [ -n "$LOCAL_AGENT_REPO" ]; then
    cd $LOCAL_DD_AGENT
    git show $AGENT_BRANCH:config.py | grep 'JMX_VERSION'
    if [ $? -ne 0 ]; then
      unset_jmx
    fi
    cd -
  else
    curl -v $REMOTE_AGENT_REPO_RAW/$AGENT_BRANCH/config.py 2>/dev/null | grep 'JMX_VERSION'
    if [ $? -ne 0 ]; then
      unset_jmx
    fi
  fi
fi

# Install the gems we need, with stubs in bin/
bundle update # Make sure to update to the latest version of omnibus-software
bin/omnibus build -l=$LOG_LEVEL $PROJECT_NAME
