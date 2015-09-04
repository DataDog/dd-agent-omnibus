#
# Dogweb Jenkins Dockerfile
#
# Used by Jenkins to run repo release scripts
# Hosted at https://quay.io/repository/datadog/dd-agent-omnibus
#

FROM quay.io/datadog/jenkins-slave

MAINTAINER Remi Hakim <remi@datadoghq.com>

RUN apt-get update \
 && apt-get install -y createrepo \
	               python-dateutil

RUN wget http://downloads.sourceforge.net/project/s3tools/s3cmd/1.5.2/s3cmd-1.5.2.tar.gz && \
	tar -xzvf s3cmd-1.5.2.tar.gz && \
	ln -s `pwd`/s3cmd-1.5.2/s3cmd /usr/bin/s3cmd

USER jenkins
# Let's fetch and install the cache invalidation script
RUN wget https://github.com/DataDog/dd-agent-omnibus/archive/master.tar.gz && \
    tar -xzvf master.tar.gz && \
    mv dd-agent-omnibus/deploy-scripts $HOME/ && \
    rm -rf master.tar.gz dd-agent-omnibus

RUN echo 'source $HOME/.rvm/scripts/rvm' >> $HOME/.bashrc
RUN /bin/bash -l -c "rvm install 2.2.2"
RUN /bin/bash -l -c "rvm use 2.2.2 && \
    rvm gemset create circleci && \
    rvm gemset use circleci && \
    gem install deb-s3 && \
    gem install httparty"
USER root
