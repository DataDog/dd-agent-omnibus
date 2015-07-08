require "./lib/ostools.rb"

name "datadog-agent"

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

build do
  ship_license 'https://raw.githubusercontent.com/DataDog/dd-agent/master/LICENSE'
  # Agent code
  mkdir  "#{install_dir}/agent/"
  copy 'checks.d', "#{install_dir}/agent/"
  copy 'checks', "#{install_dir}/agent/"
  copy 'dogstream', "#{install_dir}/agent/"
  copy 'resources', "#{install_dir}/agent/"
  copy 'utils', "#{install_dir}/agent/"
  command "cp *.py #{install_dir}/agent/"
  copy 'datadog-cert.pem', "#{install_dir}/agent/"

  mkdir "#{install_dir}/run/"


  if linux?
    # Configuration files
    mkdir '/etc/dd-agent'
      if ohai['platform_family'] == 'rhel'
        copy 'packaging/centos/datadog-agent.init', '/etc/init.d/datadog-agent'
      elsif ohai['platform_family'] == 'debian'
        copy 'packaging/debian/datadog-agent.init', '/etc/init.d/datadog-agent'
        mkdir '/lib/systemd/system'
        copy 'packaging/debian/datadog-agent.service', '/lib/systemd/system/datadog-agent.service'
        copy 'packaging/debian/start_agent.sh', '/opt/datadog-agent/bin/start_agent.sh'
        command 'chmod 755 /opt/datadog-agent/bin/start_agent.sh'
      end
      copy 'packaging/supervisor.conf', '/etc/dd-agent/supervisor.conf'
      copy 'datadog.conf.example', '/etc/dd-agent/datadog.conf.example'
      copy 'conf.d', '/etc/dd-agent/'
      mkdir '/etc/dd-agent/checks.d/'
      command 'chmod 755 /etc/init.d/datadog-agent'

      # Create symlinks
      command 'ln -sf /opt/datadog-agent/agent/agent.py /usr/bin/dd-agent'
      command 'ln -sf /opt/datadog-agent/agent/dogstatsd.py /usr/bin/dogstatsd'
      command 'ln -sf /opt/datadog-agent/agent/ddagent.py /usr/bin/dd-forwarder'
      command 'chmod 755 /usr/bin/dd-agent'
      command 'chmod 755 /usr/bin/dogstatsd'
      command 'chmod 755 /usr/bin/dd-forwarder'
  end

  if osx?
    env = {
      "PATH" => "#{install_dir}/embedded/bin/:#{ENV['PATH']}"
    }

    app_temp_dir = "#{install_dir}/agent/dist/Datadog Agent.app/Contents"
    app_temp_dir_escaped = "#{install_dir}/agent/dist/Datadog\\ Agent.app/Contents"
    pyside_build_dir =  "#{install_dir}/agent/build/bdist.macosx-10.5-intel/python2.7-standalone/app/collect/PySide"
    command_fix_shiboken = "install_name_tool -change @rpath/libshiboken-python2.7.1.2.dylib"\
                      " @executable_path/../Frameworks/libshiboken-python2.7.1.2.dylib "
    command_fix_pyside = "install_name_tool -change @rpath/libpyside-python2.7.1.2.dylib"\
                      " @executable_path/../Frameworks/libpyside-python2.7.1.2.dylib "

    # GUI
    copy "packaging/datadog-agent/win32/install_files/guidata/images", "#{install_dir}/agent"
    copy "win32/gui.py", "#{install_dir}/agent"
    copy "win32/status.html", "#{install_dir}/agent"
    mkdir "#{install_dir}/agent/packaging"
    copy "packaging/osx/app/*", "#{install_dir}/agent/packaging"

    # Shipping supervisor
    command "cp #{install_dir}/embedded/lib/python2.7/site-packages/supervisor-*/supervisor/supervisor{d,ctl}.py"\
            " #{install_dir}/agent"
    command "cd #{install_dir}/agent && "\
            "#{install_dir}/embedded/bin/python #{install_dir}/agent/setup.py py2app"\
            " && cd -", :env => env
    copy "#{install_dir}/bin/gohai", "#{app_temp_dir}/MacOS/gohai"
    copy "packaging/osx/datadog-agent", "#{app_temp_dir}/MacOS/datadog-agent"
    command "chmod a+x #{app_temp_dir_escaped}/MacOS/datadog-agent"
    # Time to patch the install, see py2app bug: (dependencies to system PySide)
    # https://bitbucket.org/ronaldoussoren/py2app/issue/143/resulting-app-mistakenly-looks-for-pyside
    copy "#{pyside_build_dir}/libshiboken-python2.7.1.2.dylib", "#{app_temp_dir}/Frameworks/libshiboken-python2.7.1.2.dylib"
    copy "#{pyside_build_dir}/libpyside-python2.7.1.2.dylib", "#{app_temp_dir}/Frameworks/libpyside-python2.7.1.2.dylib"

    command "chmod a+x #{app_temp_dir_escaped}/Frameworks/{libpyside,libshiboken}-python2.7.1.2.dylib"
    command "#{command_fix_shiboken} #{app_temp_dir_escaped}/Frameworks/libpyside-python2.7.1.2.dylib"
    command "install_name_tool -change /usr/local/lib/QtCore.framework/Versions/4/QtCore "\
            "@executable_path/../Frameworks/QtCore.framework/Versions/4/QtCore "\
            "#{app_temp_dir_escaped}/Frameworks/libpyside-python2.7.1.2.dylib"
    command "#{command_fix_shiboken} #{app_temp_dir_escaped}/Resources/lib/python2.7/lib-dynload/PySide/QtCore.so"
    command "#{command_fix_shiboken} #{app_temp_dir_escaped}/Resources/lib/python2.7/lib-dynload/PySide/QtGui.so"
    command "#{command_fix_pyside} #{app_temp_dir_escaped}/Resources/lib/python2.7/lib-dynload/PySide/QtCore.so"
    command "#{command_fix_pyside} #{app_temp_dir_escaped}/Resources/lib/python2.7/lib-dynload/PySide/QtGui.so"

    # And finally
    command "cp -Rf #{install_dir}/agent/dist/Datadog\\ Agent.app #{install_dir}"

    copy "packaging/osx/supervisor.conf", "#{install_dir}/Datadog Agent.app/Contents/Resources/supervisor.conf"
    copy "datadog.conf.example", "#{install_dir}/Datadog Agent.app/Contents/Resources/datadog.conf.example"
    copy "conf.d", "#{install_dir}/Datadog Agent.app/Contents/Resources/"
    copy "packaging/osx/com.datadoghq.Agent.plist.example", "#{install_dir}/Datadog Agent.app/Contents/Resources/com.datadoghq.Agent.plist.example"
    move "#{install_dir}/licenses", "#{install_dir}/Datadog Agent.app/Contents/Resources/licenses"
    move "#{install_dir}/sources", "#{install_dir}/Datadog Agent.app/Contents/Resources/sources"
    delete "#{install_dir}/agent"
    delete "#{install_dir}/embedded"
    delete "#{install_dir}/bin"
  end
end
