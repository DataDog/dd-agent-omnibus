require "./lib/ostools.rb"

name 'datadog-agent'
if windows?
  # Windows doesn't want our e-mail address :(
  maintainer 'Datadog Inc.'
else
  maintainer 'Datadog Packages <package@datadoghq.com>'
end
homepage 'http://www.datadoghq.com'

if ohai['platform'] == "windows"
  # Note: this is not the final install dir, not even the default one, just a convenient
  # spaceless dir in which the agent will be built.
  # Omnibus doesn't quote the Git commands it launches unfortunately, which makes it impossible
  # to put a space here...
  install_dir "C:/opt/datadog-agent/"
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

if redhat?
  runtime_dependency 'initscripts'
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
  upgrade_code '82210ed1-bbe4-4051-aa15-002ea31dde15'
  wix_candle_extension 'WixUtilExtension'
  wix_light_extension 'WixUtilExtension'
  if ENV['SIGN_WINDOWS']
    signing_identity "ECCDAE36FDCB654D2CBAB3E8975AA55469F96E4C", machine_store: true, algorithm: "SHA256"
  end
  parameters({
    'InstallDir' => install_dir,
    'InstallFiles' => "#{Omnibus::Config.source_dir()}/datadog-agent/dd-agent/packaging/datadog-agent/win32/install_files",
    'DistFiles' => "#{Omnibus::Config.source_dir()}/datadog-agent/dd-agent/dist"
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
    extra_package_file '/etc/init.d/datadog-agent'
    extra_package_file '/lib/systemd/system/datadog-agent.service'
  end

  # SysVInit service file
  if redhat?
    extra_package_file '/etc/rc.d/init.d/datadog-agent'
  end

  if suse?
    extra_package_file '/etc/init.d/datadog-agent'
    extra_package_file '/usr/lib/systemd/system/datadog-agent.service'
  end

  # Supervisord config file for the agent
  extra_package_file '/etc/dd-agent/supervisor.conf'

  # Example configuration files for the agent and the checks
  extra_package_file '/etc/dd-agent/datadog.conf.example'
  extra_package_file '/etc/dd-agent/conf.d'

  # Custom checks directory
  extra_package_file '/etc/dd-agent/checks.d'

  # Just a dummy file that needs to be in the RPM package list if we don't want it to be removed
  # during RPM upgrades. (the old files from the RPM file listthat are not in the new RPM file
  # list will get removed, that's why we need this one here)
  extra_package_file '/usr/bin/dd-agent'

  # Linux-specific dependencies
  dependency 'procps-ng'
  dependency 'sysstat'
end

# Ship supervisor anywhere but on Windows
if not windows?
  dependency 'kafka-python'
  dependency 'python-gearman'
  dependency 'snakebite'
  dependency 'supervisor'

  # Technically these ones should be shipped on Windows too at some point...
  # if we ever happen to have a customer use Postgre/pg_boucer on that platform :)
  dependency 'psycopg2'
  dependency 'pg8000'
  dependency 'zlib'
else
  # We use our own supervisor shipped as a py2exe-built executable on Windows...
  # therefore we need py2exe. We also need psutil for our home-made supervisor.
  dependency 'pywin32'
  dependency 'py2exe'
  dependency 'psutil'
  dependency 'wmi'
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
dependency 'ntplib'
dependency 'protobuf-py'
dependency 'pycrypto'
dependency 'pyopenssl'
dependency 'python-consul'
dependency 'python-etcd'
dependency 'pyyaml'
dependency 'simplejson'
dependency 'tornado'
dependency 'uptime'
dependency 'uuid'

# Check dependencies (docker-py is required on Windows too because we import it in
# dd-agent/utils/platform.py indirectly, since docker - and therefore - docker-py should
# exist on Windows at some point, we're just anticipating on things anyway :) )
dependency 'adodbapi'
dependency 'beautifulsoup4'
dependency 'dnspython'
dependency 'docker-py'
dependency 'httplib2'
dependency 'kazoo'
dependency 'paramiko'
dependency 'psutil'
dependency 'pymongo'
dependency 'pymysql'
dependency 'pysnmp'
dependency 'python-memcached'
dependency 'python-redis'
dependency 'python-rrdtool'
dependency 'pyvmomi'
dependency 'requests'
dependency 'scandir'

if not windows?
  # Additional software
  dependency 'datadogpy'
end

# datadog-gohai and datadog-metro are built last before datadog-agent since they should always
# be rebuilt (if put above, they would dirty the cache of the dependencies below
# and trigger a useless rebuild of many packages)
dependency 'datadog-gohai'
if linux? and ohai['kernel']['machine'] == 'x86_64'
  dependency 'datadog-metro'
end

# Datadog agent
dependency 'datadog-agent'

# version manifest file
dependency 'version-manifest'

exclude '\.git*'
exclude 'bundler\/git'
