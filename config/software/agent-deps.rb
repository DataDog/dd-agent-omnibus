require './lib/ostools.rb'

name 'agent-deps'
# Linux-specific dependencies
if linux?
  dependency 'procps-ng'
  dependency 'sysstat'
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
dependency 'docker-py'
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
dependency 'psutil'
dependency 'requests'

# Check dependencies
# psutil is required by the core agent on Windows
dependency 'integration-deps'





# version manifest file
dependency 'version-manifest'