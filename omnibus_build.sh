#!/bin/bash -e
PROJECT_DIR=~vagrant/dd-agent-omnibus
PROJECT_NAME=datadog-agent

echo "Show exported defaults"
cat /etc/profile.d/vagrant.sh

# Clean up omnibus artifacts
sudo rm -rf /var/cache/omnibus/pkg/*
sudo rm -rf /tmp/pip_build_vagrant

# Clean up what we installed
sudo rm -f /etc/init.d/datadog-agent
sudo rm -rf /etc/dd-agent
sudo rm -rf /opt/$PROJECT_NAME/*

cd $PROJECT_DIR
# Install the gems we need, with stubs in bin/
su vagrant -c "bundle install --binstubs"
su vagrant -c "./bin/omnibus build -l=$LOG_LEVEL $PROJECT_NAME"

# TODO: add rpm signing
#if [ #{ENV['PKG_TYPE']} == "rpm" ] && [ #{ENV['GPG_PASSPHRASE']} ] && [ #{ENV['GPG_KEY_NAME']} ]; then
#    chmod +x rpm-sign
#    su vagrant -c "./rpm-sign #{ENV['GPG_KEY_NAME']} #{ENV['GPG_PASSPHRASE']} pkg/#{project_name}-#{ENV['AGENT_VERSION']}-#{ENV['BUILD_NUMBER']}.*.rpm"
#fi
