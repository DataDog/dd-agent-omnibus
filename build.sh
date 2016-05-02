#!/bin/bash
set -x

#source ./build-env

mkdir -p pkg

mkdir -p "cache/$PLATFORM"

OMNIBUS_FOLDER=${OMNIBUS_FOLDER:-netsil-omnibus}

docker run --name "dd-agent-build-$PLATFORM" \
  -e OMNIBUS_BRANCH=$OMNIBUS_BRANCH \
  -e LOG_LEVEL=$LOG_LEVEL \
  -e AGENT_BRANCH=$AGENT_BRANCH \
  -e AGENT_VERSION=$AGENT_VERSION \
  -e RPM_SIGNING_PASSPHRASE=$RPM_SIGNING_PASSPHRASE \
  -v `pwd`/pkg:/$OMNIBUS_FOLDER/pkg \
  -v `pwd`/keys:/keys \
  -v "`pwd`/cache/$PLATFORM:/var/cache/omnibus" \
  -v `pwd`/omnibus_build.sh:/$OMNIBUS_FOLDER/omnibus_build.sh \
  "netsil/omnibus-$PLATFORM"

# -v `pwd`/config:/$OMNIBUS_FOLDER/config \
#  -e $LOCAL_AGENT_REPO=/dd-agent-repo # Only to use if you want to build from a local repo \
#  -v $LOCAL_AGENT_REPO:/dd-agent-repo # Only to use if you want to build from a local repo \

docker rm dd-agent-build-$PLATFORM

