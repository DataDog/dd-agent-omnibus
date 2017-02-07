require './lib/ostools.rb'

name 'datadog-agent-integration-deps'

dependency 'datadog-agent'

# These are the deps for the agent
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

dependency 'psycopg2'
dependency 'zlib'

if not windows?
  dependency 'kafka-python'
  dependency 'python-gearman'
  dependency 'snakebite'
end
