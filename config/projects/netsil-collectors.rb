require "./lib/ostools.rb"

name 'netsil-collectors'
maintainer 'Netsil collectors <kevin@netsil.com>'
homepage 'http://www.netsil.com'
install_dir '/opt/netsil/collectors'

build_version do
  source :git, from_dependency: 'datadog-agent'
  output_format :dd_agent_format
end

build_iteration 1

description 'Netsil Collector Suite
The Netsil Collector Suite bundles a traffic-collector, metadata-collector, 
and a datadog-agent
'
#description 'Datadog Monitoring Agent
# The Datadog Monitoring Agent is a lightweight process that monitors system
# processes and services, and sends information back to your Datadog account.
# .
# This package installs and runs the advanced Agent daemon, which queues and
# forwards metrics from your applications as well as system services.
# .
# See http://www.datadoghq.com/ for more information
#'

#################################
##### Install datadog-agent #####
#################################
# This file is "datadog-agent.rb" in the original dd-agent-omnibus repo

# ------------------------------------
# Generic package information
# ------------------------------------

# .deb specific flags
package :deb do
  vendor 'Datadog <info@datadoghq.com>'
  epoch 1
  license 'Simplified BSD License'
  section 'utils'
  priority 'extra'
end

# .rpm specific flags
package :rpm do
  vendor 'Datadog <package@datadoghq.com>'
  epoch 1
  license 'Simplified BSD License'
  category 'System Environment/Daemons'
  priority 'extra'
  if ENV.has_key?('RPM_SIGNING_PASSPHRASE') and not ENV['RPM_SIGNING_PASSPHRASE'].empty?
    signing_passphrase "#{ENV['RPM_SIGNING_PASSPHRASE']}"
  end
end

# OSX .pkg specific flags
package :pkg do
  identifier 'com.datadoghq.agent'
  signing_identity 'Developer ID Installer: Datadog, Inc. (JKFCB4CN7C)'
end
compress :dmg do
  window_bounds '200, 200, 750, 600'
  pkg_position '10, 10'
end

# Note: this is to try to avoid issues when upgrading from an
# old version of the agent which shipped also a datadog-agent-base
# package.
if redhat?
  replace 'datadog-agent-base < 5.0.0'
  replace 'datadog-agent-lib < 5.0.0'
elsif debian?
  replace 'datadog-agent-base (<< 5.0.0)'
  replace 'datadog-agent-lib (<< 5.0.0)'
  conflict 'datadog-agent-base (<< 5.0.0)'
end

# ------------------------------------
# OS specific DSLs and dependencies
# ------------------------------------

# Linux
if linux?
  # Debian
  if debian?
    extra_package_file '/lib/systemd/system/netsil-datadog-agent.service'
  end

  # SysVInit service file
  # luhkevin: We have replaced netsil-datadog-agent init script with a "master" init script
  # This master init script will invoke the init of both the datadog-agent (now in our install_dir) and our own collectors
  if redhat?
    extra_package_file '/etc/rc.d/init.d/netsil-collectors'
    extra_package_file '/etc/rc.d/init.d/netsil-datadog-agent'
  else
    extra_package_file '/etc/init.d/netsil-collectors'
    extra_package_file '/etc/init.d/netsil-datadog-agent'
  end

  # Supervisord config file for the agent
  extra_package_file '/etc/netsil-dd-agent/supervisor.conf'

  # Example configuration files for the agent and the checks
  extra_package_file '/etc/netsil-dd-agent/datadog.conf.example'
  extra_package_file '/etc/netsil-dd-agent/conf.d'

  # Custom checks directory
  extra_package_file '/etc/netsil-dd-agent/checks.d'

  # Just a dummy file that needs to be in the RPM package list if we don't want it to be removed
  # during RPM upgrades. (the old files from the RPM file listthat are not in the new RPM file
  # list will get removed, that's why we need this one here)
  extra_package_file '/usr/bin/netsil-dd-agent'

  # Linux-specific dependencies
  dependency 'procps-ng'
  dependency 'sysstat'
end

# Mac and Windows
if osx? or windows?
  dependency 'gui'
end

# ------------------------------------
# Dependencies
# ------------------------------------

# creates required build directories
dependency 'preparation'

# Agent dependencies
dependency 'boto'
dependency 'docker-py'
dependency 'ntplib'
dependency 'pycrypto'
dependency 'pyopenssl'
dependency 'python-consul'
dependency 'python-etcd'
dependency 'pyyaml'
dependency 'simplejson'
dependency 'supervisor'
dependency 'tornado'
dependency 'uptime'
dependency 'uuid'
dependency 'zlib'

# Check dependencies
dependency 'adodbapi'
dependency 'dnspython'
dependency 'httplib2'
dependency 'kafka-python'
dependency 'kazoo'
dependency 'paramiko'
dependency 'pg8000'
dependency 'psutil'
dependency 'psycopg2'
dependency 'pymongo'
dependency 'pymysql'
dependency 'pysnmp'
dependency 'python-gearman'
dependency 'python-memcached'
dependency 'python-redis'
dependency 'python-rrdtool'
dependency 'pyvmomi'
dependency 'requests'
dependency 'snakebite'

# Additional software
dependency 'datadogpy'

# datadog-gohai and datadog-metro are built last before datadog-agent since they should always
# be rebuilt (if put above, they would dirty the cache of the dependencies below
# and trigger a useless rebuild of many packages)
dependency 'datadog-gohai'
if linux? and ohai['kernel']['machine'] == 'x86_64'
  dependency 'datadog-metro'
end

# Datadog agent
dependency 'datadog-agent'


#####################################
##### Install netsil-collectors #####
#####################################
dependency 'traffic-collector'
dependency 'netsil-collectors-conf'
dependency 'metadata-collector'

# version manifest file
dependency 'version-manifest'

exclude '\.git*'
exclude 'bundler\/git'
