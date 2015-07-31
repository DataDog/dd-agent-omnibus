require "./lib/ostools.rb"

name 'datadog-agent'
if windows?
  # Windows doesn't want our e-mail address :(
  maintainer 'Datadog'
else
  maintainer 'Datadog Packages <package@datadoghq.com>'
end
homepage 'http://www.datadoghq.com'
if ohai['platform'] == "windows"
  install_dir "C:/Agent"
else
  install_dir '/opt/datadog-agent'
end

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

# Windows .msi specific flags
package :msi do
  # For a consistent package management, please NEVER change this code
  upgrade_code '9E1DEDC4-DE86-4714-8325-BEF9B08E34A8'
  parameters({
    'InstallDir' => install_dir,
    'ExampleConfigsWixFile' => "#{Omnibus::Config.source_dir()}\\dd-agent\\example-config-files.wxs",
    'InstallFiles' => "#{Omnibus::Config.source_dir()}\\dd-agent\\packaging\\datadog-agent\\win32\\install_files",
    'FindReplaceDir' => "#{Omnibus::Config.source_dir()}\\dd-agent\\packaging\\datadog-agent\\win32\\wix",
    'ExampleConfigSourceDir' => "#{Omnibus::Config.source_dir()}\\dd-agent\\conf.d",
    'AgentSourceDir' => "#{Omnibus::Config.source_dir()}\\dd-agent",
  })
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
  extra_package_file "/etc/dd-agent/conf.d"

  # Custom checks directory
  extra_package_file "/etc/dd-agent/checks.d"

  # Symbolic links to the agent "binaries"
  extra_package_file '/usr/bin/dd-agent'
  extra_package_file '/usr/bin/dogstatsd'
  extra_package_file '/usr/bin/dd-forwarder'

  # Linux-specific dependencies
  dependency 'procps-ng'
  dependency 'sysstat'

end

# Ship supervisor anywhere but on Windows
if not windows?
  dependency 'supervisor'
else
  # We use our own supervisor shipped as a py2exe-built executable on Windows...
  # therefore we need py2exe
  dependency 'pywin32'
  dependency 'py2exe'
end

# Mac and Windows
if osx? or windows?
  dependency 'gui'
end

# Docker only exists on Linux
if linux?
  dependency 'docker-py'
end

# ------------------------------------
# Dependencies
# ------------------------------------

# creates required build directories
dependency 'preparation'

# Agent dependencies
dependency 'boto'
dependency 'ntplib'
dependency 'pycrypto'
dependency 'pyopenssl'
dependency 'pyyaml'
dependency 'simplejson'
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
