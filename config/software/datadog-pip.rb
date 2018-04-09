# Unless explicitly stated otherwise all files in this repository are licensed
# under the Apache License Version 2.0.
# This product includes software developed at Datadog (https:#www.datadoghq.com/).
# Copyright 2018 Datadog, Inc.

require './lib/ostools.rb'

name 'datadog-pip'

dependency 'pip'
dependency 'datadog-agent'

source git: 'https://github.com/DataDog/pip.git'

relative_path 'pip'

pip_version = ENV['PIP_VERSION']
if pip_version.nil? || pip_version.empty?
  pip_version = 'trishankatdatadog/9.0.3.tuf-in-toto'
end
default_version pip_version


build do
  if windows?
    python_bin = "\"#{windows_safe_path(install_dir)}\\embedded\\python.exe\""
    command("#{python_bin} -m pip install wheel", cwd: "#{project_dir}/..")
    pip "wheel .", :cwd => project_dir
    python_pip = "\"import pip, glob; pip.main(['install', '--disable-pip-version-check', '--upgrade'] + ['{}\[tuf-in-toto\]'.format(k) for k in glob.glob('pip/pip*.whl')])\""
    command("#{python_bin} -c #{python_pip}", cwd: "#{project_dir}/..")
  else
    pip "install --disable-pip-version-check --upgrade .\[tuf-in-toto\]", :cwd => project_dir
  end
end
