#!/bin/bash -e

###########################
#
# WARNING: You need to rebuild the docker images if you do any changes to this file
#
############################

PROJECT_DIR=dd-agent-omnibus
PROJECT_NAME=datadog-agent
LOG_LEVEL=${LOG_LEVEL:-"info"}
REMOTE_AGENT_REPO_RAW="https://raw.githubusercontent.com/DataDog/dd-agent"
LOCAL_DD_AGENT="/dd-agent-repo"

set -e

# Clean up omnibus artifacts
rm -rf /var/cache/omnibus/pkg/*

# Clean up what we installed
rm -f /etc/init.d/datadog-agent
rm -rf /etc/dd-agent
rm -rf /opt/$PROJECT_NAME/*

builtin cd $PROJECT_DIR

# make sure we can run the ruby script with the default ruby branch
bundle update

# Loading release information from release.json
vars=$(bundle exec ruby load_realease.rb)

if [ -z "$vars" ]; then
  echo "Error: could not load release info"
  exit 1
fi

# Export variables from the release.json
IFS_DEFAULT=$IFS
IFS=$'\n'; for line in $vars
do
  key=`echo $line | cut -d ' ' -f 1`
  value=`echo $line | cut -d ' ' -f 2`
  echo "setting $key => $value"
  export "$key=$value"
done
IFS=$IFS_DEFAULT

# If an RPM_SIGNING_PASSPHRASE has been passed, let's import the signing key
if [ -n "$RPM_SIGNING_PASSPHRASE" ]; then
  gpg --import /keys/RPM-SIGNING-KEY.private
fi

# NOTE: JMX_VERSION plays no role <5.14.x (jmx bundled with agent)
# If "current" JMX version, set it from the corresponding agent branch config.py
if [ -n "$LOCAL_AGENT_REPO" ]; then
  cd $LOCAL_DD_AGENT
  JMX_VERSION=$(git show $AGENT_BRANCH:config.py | grep 'JMX_VERSION' | cut -f2 -d'=' | tr -d ' "')
  cd -
else
  JMX_VERSION=$(curl -v $REMOTE_AGENT_REPO_RAW/$AGENT_BRANCH/config.py 2>/dev/null | grep 'JMX_VERSION' | cut -f2 -d'=' | tr -d ' "')
fi
export JMX_VERSION=$JMX_VERSION

# update ruby omnibus package
bundle update # Make sure to update to the latest version of omnibus-software

bin/omnibus build -l=$LOG_LEVEL $PROJECT_NAME
