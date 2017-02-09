require './lib/ostools.rb'

name 'integration-deps'

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

if not windows?
  dependency 'kafka-python'
  dependency 'psycopg2'
  dependency 'python-gearman'
  dependency 'snakebite'
end
