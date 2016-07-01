#!/bin/bash
set -x

#source ./build-env

mkdir -p pkg

#mkdir -p "cache/$PLATFORM"

OMNIBUS_FOLDER=${OMNIBUS_FOLDER:-netsil-omnibus}
OMNIBUS_BUILD=${OMNIBUS_STAGING:-/var/lib/docker/cache/omnibus}

docker run --name "dd-agent-build-$PLATFORM" \
  -e OMNIBUS_BRANCH=$OMNIBUS_BRANCH \
  -e LOG_LEVEL=$LOG_LEVEL \
  -e AGENT_BRANCH=$AGENT_BRANCH \
  -e AGENT_VERSION=$AGENT_VERSION \
  -e RPM_SIGNING_PASSPHRASE=$RPM_SIGNING_PASSPHRASE \
  -v ${OMNIBUS_BUILD}/staging:/root/omnibus/staging \
  -v ${OMNIBUS_BUILD}/cache:/var/cache/omnibus \
  -v `pwd`/pkg:/$OMNIBUS_FOLDER/pkg \
  -v `pwd`/config:/$OMNIBUS_FOLDER/config \
  -v `pwd`/keys:/keys \
  -v `pwd`/lib:/$OMNIBUS_FOLDER/lib \
  -v `pwd`/package-scripts:/$OMNIBUS_FOLDER/package-scripts \
  -v `pwd`/resources:/$OMNIBUS_FOLDER/resources \
  -v `pwd`/omnibus.rb:/$OMNIBUS_FOLDER/omnibus.rb \
  -v `pwd`/omnibus_build.sh:/$OMNIBUS_FOLDER/omnibus_build.sh \
  "netsil/omnibus-$PLATFORM"

# -v `pwd`/config:/$OMNIBUS_FOLDER/config \
#  -e $LOCAL_AGENT_REPO=/dd-agent-repo # Only to use if you want to build from a local repo \
#  -v $LOCAL_AGENT_REPO:/dd-agent-repo # Only to use if you want to build from a local repo \

docker rm dd-agent-build-$PLATFORM

