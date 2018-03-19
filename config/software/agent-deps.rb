require './lib/ostools.rb'

name 'agent-deps'
# Linux-specific dependencies
if linux?
  dependency 'procps-ng'
  dependency 'sysstat'
  dependency 'nfsiostat'
end
# Ship supervisor anywhere but on Windows
if not windows?
  dependency 'supervisor'
  dependency 'zlib'
else
  # We use our own supervisor shipped as a py2exe-built executable on Windows...
  # therefore we need py2exe. We also need psutil for our home-made supervisor.
  dependency 'pywin32'
  dependency 'py2exe'
  dependency 'wmi'
end

# Mac and Windows
if osx? or windows?
  dependency 'gui'
end

# ------------------------------------
# Dependencies
# ------------------------------------

# Agent dependencies
dependency 'boto'
dependency 'cacerts'
dependency 'docker-py'

dependency 'jmxfetch'
dependency 'jmxterm'

dependency 'kazoo'
dependency 'ntplib'
dependency 'protobuf-py'
dependency 'psutil'
dependency 'pyopenssl'
dependency 'python-consul'
dependency 'python-etcd'
dependency 'pyyaml'
dependency 'rancher-metadata'
dependency 'requests'
dependency 'simplejson'
dependency 'tornado'
dependency 'uptime'
dependency 'uuid'
dependency 'prometheus-client'
