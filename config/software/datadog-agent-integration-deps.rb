require './lib/ostools.rb'

name 'datadog-agent-integration-deps'

dependency 'datadog-agent'

# These are the deps for the integrations that are shipped with the agent
# we may also put any other C deps here that other integrations need
dependency 'adodbapi'
dependency 'beautifulsoup4'
dependency 'dnspython'
dependency 'httplib2'
dependency 'kazoo'
dependency 'paramiko'
dependency 'pg8000'
dependency 'pymongo'
dependency 'pymysql'
dependency 'pysnmp'
dependency 'python-memcached'
dependency 'python-redis'
dependency 'python-rrdtool'
dependency 'pyvmomi'
dependency 'scandir'

# This didn't use to be on windows.
# We have bumped the version to one that builds successfully on windows
dependency 'psycopg2'

if not windows?
  dependency 'kafka-python'
  dependency 'python-gearman'
  dependency 'snakebite'
end
