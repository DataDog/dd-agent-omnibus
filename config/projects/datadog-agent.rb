name 'datadog-agent'
maintainer 'Etienne Omnitests <etienne.lafarge@datadoghq.com>'
homepage 'http://www.datadoghq.com'
install_dir '/opt/datadog-agent'

build_version do
  source :git, from_dependency: 'datadog-agent'
  output_format :dd_agent_format
end

build_iteration 1

description 'Datadog Monitoring Agent
 The Datadog Monitoring Agent is a lightweight process that monitors system
 processes and services, and sends information back to your Datadog account.
 .
 This package installs and runs the advanced Agent daemon, which queues and
 forwards metrics from your applications as well as system services.
 .
 See http://www.datadoghq.com/ for more information
'

# .deb specific flags
package :deb do
  vendor 'DataDog <info@datadoghq.com>'
  license 'Simplified BSD License'
  section 'utils'
  priority 'extra'
end

package :rpm do
  vendor 'DataDog <info@datadoghq.com>'
  license 'Simplified BSD License'
  category 'System Environment/Daemons'
  priority 'extra'
  if ENV.has_key?('RPM_SIGNING_PASSPHRASE') and not ENV['RPM_SIGNING_PASSPHRASE'].empty?
    signing_passphrase "#{ENV['RPM_SIGNING_PASSPHRASE']}"
  end
end

# Note: this is to try to avoid issues when upgrading from an
# old version of the agent which shipped also a datadog-agent-base
# package.
if ohai['platform_family'] == 'rhel'
  replace 'datadog-agent-base < 5.0.0'
  replace 'datadog-agent-lib < 5.0.0'
elsif ohai['platform_family'] == 'debian'
  replace 'datadog-agent-base (<< 5.0.0)'
  replace 'datadog-agent-lib (<< 5.0.0)'
  conflict 'datadog-agent-base (<< 5.0.0)'
end

extra_package_file '/etc/init.d/datadog-agent'
if ohai['platform_family'] == 'debian'
  extra_package_file '/lib/systemd/system/datadog-agent.service'
end
extra_package_file '/etc/dd-agent'
extra_package_file '/usr/bin/dd-agent'
extra_package_file '/usr/bin/dogstatsd'
extra_package_file '/usr/bin/dd-forwarder'

# creates required build directories
dependency 'preparation'

# Agent dependencies
dependency 'boto'
dependency 'datadog-gohai'
dependency 'ntplib'
dependency 'procps-ng'
dependency 'pycrypto'
dependency 'pyopenssl'
dependency 'pyyaml'
dependency 'simplejson'
dependency 'supervisor'
dependency 'sysstat'
dependency 'tornado'
dependency 'uuid'
dependency 'zlib'

# Check dependencies
dependency 'adodbapi'
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

# Datadog agent
dependency 'datadog-agent'

# version manifest file
dependency 'version-manifest'

exclude '\.git*'
exclude 'bundler\/git'
