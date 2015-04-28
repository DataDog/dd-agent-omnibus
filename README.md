Datadog Agent - Omnibus Project
================

This is an [Omnibus](https://github.com/opscode/omnibus) project to build the Datadog Agent packages.

It's using a [fork](https://github.com/DataDog/omnibus-ruby/compare/chef:v3.2.2...custom3.2.2-2) of the official 3.2.2 release of the Omnibus project.

Builds are run in docker containers with Circleci.
See:
* https://github.com/DataDog/docker-dd-agent-build-deb-i386
* https://github.com/DataDog/docker-dd-agent-build-rpm-i386
* https://github.com/DataDog/docker-dd-agent-build-deb-x64
* https://github.com/DataDog/docker-dd-agent-build-rpm-x64


## Build a package locally

* Install Docker

* Run the following script with the desired parameters

```bash
PLATFORM="deb-x64" # must be in "deb-x64", "deb-i386", "rpm-x64", "rpm-i386"
AGENT_BRANCH="master" # Branch of dd-agent repo to use, default "master"
OMNIBUS_BRANCH="master" # Branch of dd-agent-omnibus repo to use, default "master"
AGENT_VERSION="5.4.0" # default to the latest tag on that branch
LOG_LEVEL="debug" # default to "info"
LOCAL_AGENT_REPO="~/dd-agent" # Path to a local repo of the agent to build from. Defaut is not set and the build will be done against the github repo

mkdir -p pkg
mkdir -p "cache/$PLATFORM"
docker run --name "dd-agent-build-$PLATFORM" \
  -e OMNIBUS_BRANCH=$OMNIBUS_BRANCH \
  -e LOG_LEVEL=$LOG_LEVEL \
  -e AGENT_BRANCH=$AGENT_BRANCH \
  -e AGENT_VERSION=$AGENT_VERSION \
  -v `pwd`/pkg:/dd-agent-omnibus/pkg \
  -v "`pwd`/cache/$PLATFORM:/var/cache/omnibus" \
  "datadog/docker-dd-agent-build-$PLATFORM"
```
