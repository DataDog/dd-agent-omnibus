name "datadog-agent"
maintainer "Datadog Packages <package@datadoghq.com>"
homepage "http://www.datadoghq.com"
install_dir    "/opt/datadog-agent"
build_version   ENV['AGENT_VERSION'] || "5.0.0"
build_iteration ENV['BUILD_NUMBER'] || 0
vendor "Datadog"
epoch 1
description "Datadog Monitoring Agent
 The Datadog Monitoring Agent is a lightweight process that monitors system
 processes and services, and sends information back to your Datadog account.
 .
 This package installs and runs the advanced Agent daemon, which queues and
 forwards metrics from your applications as well as system services.
 .
 See http://www.datadoghq.com/ for more information
"
platform_in_iteration false

if ENV['PKG_TYPE'] == "rpm"
    replaces "datadog-agent-base < 5.0.0"
    replaces "datadog-agent-lib < 5.0.0"

elsif ENV['PKG_TYPE'] == "deb"
    replaces "datadog-agent (<< #{ENV['AGENT_VERSION']})"
    replaces "datadog-agent-base (<< 5.0.0)"
    replaces "datadog-agent-lib (<< 5.0.0)"
    conflict "datadog-agent-base (<< 5.0.0)"
end

extra_package_file "/etc/init.d/datadog-agent"
extra_package_file "/etc/dd-agent"
extra_package_file "/usr/bin/dd-agent"
extra_package_file "/usr/bin/dogstatsd"
extra_package_file "/usr/bin/dd-forwarder"
extra_package_file "/usr/bin/bernard"

provides "datadog-agent-base"


# creates required build directories
dependency "preparation"

# Agent dependencies
dependency "boto"
dependency "datadog-gohai"
dependency "ntplib"
dependency "procps-ng"
dependency "pycrypto"
dependency "pyopenssl"
dependency "python-readline"
dependency "pyyaml"
dependency "simplejson"
dependency "supervisor"
dependency "sysstat"
dependency "tornado"
dependency "uuid"
dependency "zlib"

# Check dependencies
dependency "adodbapi"
dependency "httplib2"
dependency "kafka-python"
dependency "kazoo"
dependency "paramiko"
dependency "pg8000"
dependency "psutil"
dependency "pymongo"
dependency "pymysql"
dependency "pysnmp"
dependency "python-gearman"
dependency "python-memcached"
dependency "python-redis"
dependency "python-rrdtool"
dependency "pyvmomi"
dependency "requests"
dependency "snakebite"

# Datadog agent
dependency "datadog-agent"

# version manifest file
dependency "version-manifest"

exclude "\.git*"
exclude "bundler\/git"
