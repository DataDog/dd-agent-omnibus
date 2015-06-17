name 'datadog-agent'

local_agent_repo = ENV['LOCAL_AGENT_REPO']
if local_agent_repo.nil? || local_agent_repo.empty?
  source git: 'https://github.com/DataDog/dd-agent.git'
else
  # For local development
  source path: ENV['LOCAL_AGENT_REPO']
end

agent_branch = ENV['AGENT_BRANCH']
if agent_branch.nil? || agent_branch.empty?
  default_version 'master'
else
  default_version agent_branch
end

relative_path 'dd-agent'
always_build true

env = {
  'PATH' => "#{install_dir}/embedded/bin/:#{ENV['PATH']}"
}

app_temp_dir = "#{install_dir}/agent/dist/Datadog\\ Agent.app/Contents"
pyside_build_dir =  "#{install_dir}/agent/build/bdist.macosx-10.5-intel/python2.7-standalone/app/collect/PySide"
command_fix_shiboken = 'install_name_tool -change @rpath/libshiboken-python2.7.1.2.dylib'\
                      ' @executable_path/../Frameworks/libshiboken-python2.7.1.2.dylib '
command_fix_pyside = 'install_name_tool -change @rpath/libpyside-python2.7.1.2.dylib'\
                      ' @executable_path/../Frameworks/libpyside-python2.7.1.2.dylib '\

build do
  license 'https://raw.githubusercontent.com/DataDog/dd-agent/master/LICENSE'
  # Agent code
  command "mkdir -p #{install_dir}/agent/"
  command "cp -R checks.d #{install_dir}/agent/"
  command "cp -R checks #{install_dir}/agent/"
  command "cp -R dogstream #{install_dir}/agent/"
  command "cp -R resources #{install_dir}/agent/"
  command "cp -R utils #{install_dir}/agent/"
  command "cp *.py #{install_dir}/agent/"
  command "cp datadog-cert.pem #{install_dir}/agent/"

  # Internal /run directory
  command "mkdir -p #{install_dir}/run"

  # Configuration files
  if Ohai['platform_family'] == 'rhel'
    command 'mkdir -p /etc/dd-agent'
    command 'cp packaging/centos/datadog-agent.init /etc/init.d/datadog-agent'
  elsif Ohai['platform_family'] == 'debian'
    command 'mkdir -p /etc/dd-agent'
    command 'cp packaging/debian/datadog-agent.init /etc/init.d/datadog-agent'
    command 'mkdir -p /lib/systemd/system'
    command 'cp packaging/debian/datadog-agent.service /lib/systemd/system/datadog-agent.service'
    command 'cp packaging/debian/start_agent.sh /opt/datadog-agent/bin/start_agent.sh'
    command 'chmod 755 /opt/datadog-agent/bin/start_agent.sh'
  end

  if %w(rhel debian).include? Ohai['platform_family']
    command 'cp packaging/supervisor.conf /etc/dd-agent/supervisor.conf'
    command 'cp datadog.conf.example /etc/dd-agent/datadog.conf.example'
    command 'cp -R conf.d /etc/dd-agent/'
    command 'mkdir -p /etc/dd-agent/checks.d/'
    command 'chmod 755 /etc/init.d/datadog-agent'

    # Create symlinks
    command 'ln -sf /opt/datadog-agent/agent/agent.py /usr/bin/dd-agent'
    command 'ln -sf /opt/datadog-agent/agent/dogstatsd.py /usr/bin/dogstatsd'
    command 'ln -sf /opt/datadog-agent/agent/ddagent.py /usr/bin/dd-forwarder'
    command 'chmod 755 /usr/bin/dd-agent'
    command 'chmod 755 /usr/bin/dogstatsd'
    command 'chmod 755 /usr/bin/dd-forwarder'

  # Mac
  else
    # Command line tool
    command "cp packaging/osx/datadog-agent #{install_dir}/bin"
    command "chmod 755 #{install_dir}/bin/datadog-agent"

    # GUI
    command "cp -R packaging/datadog-agent/win32/install_files/guidata/images #{install_dir}/agent"
    command "cp win32/gui.py #{install_dir}/agent"
    command "cp win32/status.html #{install_dir}/agent"
    command "mkdir -p #{install_dir}/agent/packaging"
    command "cp packaging/osx/app/* #{install_dir}/agent/packaging"

    command "cd #{install_dir}/agent && "\
            "#{install_dir}/embedded/bin/python #{install_dir}/agent/setup.py py2app"\
            ' && cd -', env: env

    # Time to patch the install, see py2app bug: (dependencies to system PySide)
    # https://bitbucket.org/ronaldoussoren/py2app/issue/143/resulting-app-mistakenly-looks-for-pyside
    command "cp #{pyside_build_dir}/libshiboken-python2.7.1.2.dylib #{app_temp_dir}/Frameworks"
    command "cp #{pyside_build_dir}/libpyside-python2.7.1.2.dylib #{app_temp_dir}/Frameworks"
    command "chmod a+x #{app_temp_dir}/Frameworks/{libpyside,libshiboken}-python2.7.1.2.dylib"
    command "#{command_fix_shiboken} #{app_temp_dir}/Frameworks/libpyside-python2.7.1.2.dylib"
    command 'install_name_tool -change /usr/local/lib/QtCore.framework/Versions/4/QtCore '\
            '@executable_path/../Frameworks/QtCore.framework/Versions/4/QtCore '\
            "#{app_temp_dir}/Frameworks/libpyside-python2.7.1.2.dylib"
    command "#{command_fix_shiboken} #{app_temp_dir}/Resources/lib/python2.7/lib-dynload/PySide/QtCore.so"
    command "#{command_fix_shiboken} #{app_temp_dir}/Resources/lib/python2.7/lib-dynload/PySide/QtGui.so"
    command "#{command_fix_pyside} #{app_temp_dir}/Resources/lib/python2.7/lib-dynload/PySide/QtCore.so"
    command "#{command_fix_pyside} #{app_temp_dir}/Resources/lib/python2.7/lib-dynload/PySide/QtGui.so"

    # And finally
    command "mv #{install_dir}/agent/dist/Datadog\\ Agent.app #{install_dir}"

    # Clean GUI related things
    %w(build dist images gui.py status.html packaging Datadog_Agent.egg-info).each do |file|
        command "rm -rf #{install_dir}/agent/#{file}"
    end
    %w(py2app macholib modulegraph altgraph).each do |package|
        command "yes | #{install_dir}/embedded/bin/pip uninstall #{package}"
    end
    %w(pyside guidata spyderlib).each do |dependency_name|
      # Installed with `python setup.py install`, needs to be uninstalled manually
      command "cat #{install_dir}/embedded/#{dependency_name}-files.txt | xargs rm -rf \"{}\""
      command "rm -f #{install_dir}/embedded/#{dependency_name}-files.txt"
    end

    # conf
    command "mkdir -p #{install_dir}/etc"
    command "grep -v 'user=dd-agent' packaging/supervisor.conf > #{install_dir}/etc/supervisor.conf"
    command "cp datadog.conf.example #{install_dir}/etc/datadog.conf.example"
    command "cp -R conf.d #{install_dir}/etc/"
    command "cp packaging/osx/com.datadoghq.Agent.plist.example #{install_dir}/etc/"
  end
end
