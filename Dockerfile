#
# Dogweb Jenkins Dockerfile
#
# Used by Jenkins to run repo release scripts
# Hosted at https://quay.io/repository/datadog/dd-agent-omnibus
#

FROM quay.io/datadog/jenkins-slave

MAINTAINER Remi Hakim <remi@datadoghq.com>

RUN apt-get update \
 && apt-get install -y createrepo
