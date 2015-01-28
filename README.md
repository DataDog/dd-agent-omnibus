Datadog Agent - Omnibus Project
================

This is an [Omnibus](https://github.com/opscode/omnibus) project to build the Datadog Agent packages.

It's using a [fork](https://github.com/DataDog/omnibus-ruby/compare/opscode:v3.2.2...custom3.2.2-2) of the official 3.2.2 release of the Omnibus project.

## Use omnibus locally

* Clone the dd-agent-omnibus repo

* Install necessary vagrant plugins
```
vagrant plugin install vagrant-cachier --plugin-version=0.7.2
vagrant plugin install vagrant-berkshelf --plugin-version=2.0.1
vagrant plugin install vagrant-omnibus --plugin-version=1.4.1
```
* Build one package from the GitHub repo master branch
```
DISTRO=debian ARCH=x64 ./build
```

Supported options:

* Build matrix:

| DISTRO/ARCH | i386 | x64 |
|:-----------:|:----:|:---:|
|    debian   |   y  |  y  |
|    centos   |   y  |  y  |

* `LOCAL_AGENT_REPO` can be used if you want it to build a local version of the agent code. It should be an absolute path to your local copy of dd-agent.
* `FORCE_RELOAD` if set will force a reload of your VM, can be useful if you're having with filesystem sync for instance.
