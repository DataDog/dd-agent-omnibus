require "./lib/ostools.rb"

name 'datadog-agent'
maintainer 'Datadog <package@datadoghq.com>'
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

# ------------------------------------
# Generic package information
# ------------------------------------

# .deb specific flags
package :deb do
  vendor 'Datadog <info@datadoghq.com>'
  license 'Simplified BSD License'
  section 'utils'
  priority 'extra'
end

# .rpm specific flags
package :rpm do
  vendor 'Datadog <package@datadoghq.com>'
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
    extra_package_file '/lib/systemd/system/datadog-agent.service'
  end

  # SysVInit service file
  if redhat?
    extra_package_file '/etc/rc.d/init.d/datadog-agent'
  else
    extra_package_file '/etc/init.d/datadog-agent'
  end

  # Supervisord config file for the agent
  extra_package_file "/etc/dd-agent/supervisor.conf"

  # Example configuration files for the agent and the checks
  extra_package_file "/etc/dd-agent/datadog.conf.example"
  extra_package_file "/etc/dd-agent/conf.d/activemq.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/activemq_58.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/activemq_xml.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/apache.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/btrfs.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/cacti.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/cassandra.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/couch.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/couchbase.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/directory.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/docker.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/elastic.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/etcd.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/fluentd.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/gearmand.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/go_expvar.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/gunicorn.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/haproxy.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/hdfs.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/http_check.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/iis.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/jenkins.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/jmx.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/kafka.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/kafka_consumer.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/kyototycoon.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/lighttpd.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/marathon.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/mcache.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/mesos.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/mesos_master.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/mesos_slave.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/mongo.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/mysql.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/nagios.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/nginx.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/pgbouncer.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/php_fpm.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/postfix.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/postgres.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/process.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/rabbitmq.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/redisdb.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/riak.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/riakcs.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/snmp.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/solr.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/sqlserver.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/ssh_check.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/supervisord.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/system_core.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/system_swap.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/tcp_check.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/teamcity.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/tokumx.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/tomcat.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/varnish.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/vsphere.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/win32_event_log.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/windows_service.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/wmi_check.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/zk.yaml.example"
  extra_package_file "/etc/dd-agent/conf.d/agent_metrics.yaml.default"
  extra_package_file "/etc/dd-agent/conf.d/disk.yaml.default"
  extra_package_file "/etc/dd-agent/conf.d/network.yaml.default"
  extra_package_file "/etc/dd-agent/conf.d/ntp.yaml.default"

  # Symbolic links to the agent "binaries"
  extra_package_file '/usr/bin/dd-agent'
  extra_package_file '/usr/bin/dogstatsd'
  extra_package_file '/usr/bin/dd-forwarder'

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
dependency 'pyyaml'
dependency 'simplejson'
dependency 'supervisor'
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

# Datadog gohai is built last before dataadog agent since it should always
# be rebuilt (if put above, it would dirty the cache of the dependencies below
# and trigger a useless rebuild of many packages)
dependency 'datadog-gohai'

# Datadog agent
dependency 'datadog-agent'

# version manifest file
dependency 'version-manifest'

exclude '\.git*'
exclude 'bundler\/git'
