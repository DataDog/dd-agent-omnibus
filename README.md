Datadog Agent - Omnibus Project
================

This is an [Omnibus](https://github.com/opscode/omnibus) project to build the Datadog Agent packages.

It's using a [fork](https://github.com/DataDog/omnibus-ruby/compare/opscode:3.0-stable...custom3.0) of the official 3.0 release of the Omnibus project.

## Use omnibus locally

* Clone the dd-agent-omnibus repo

* Install necessary vagrant plugins
```
vagrant plugin install vagrant-cachier --plugin-version=0.7.2
vagrant plugin install vagrant-berkshelf --plugin-version=2.0.1
vagrant plugin install vagrant-omnibus --plugin-version=1.4.1
```
* Build one package
```
AGENT_VERSION=5.0.0 BUILD_NUMBER=1 AGENT_BRANCH=leo/memorylimit PKG_TYPE=deb ARCH=x64 vagrant reload debian-x64 --provision
```

PKG_TYPE should be "deb" or "rpm".

ARCH should be "i386" or "x64".

You can use `AGENT_LOCAL_REPO` variable and set it to a path on your host machine to use your repo, otherwise it will pull from the [dd-agent Github repository](https://github.com/datadog/dd-agent)

