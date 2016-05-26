require './lib/ostools.rb'

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

build do
  ship_license 'https://raw.githubusercontent.com/DataDog/dd-agent/master/LICENSE'

  mkdir  "#{install_dir}/agent/"

  # Note: the copy DSL isn't working as expected when syncing folders on windows...
  if linux? or osx?
    # Agent code
    copy 'checks.d', "#{install_dir}/agent/"
    copy 'checks', "#{install_dir}/agent/"
    copy 'dogstream', "#{install_dir}/agent/"
    copy 'utils', "#{install_dir}/agent/"
  end

  command "cp *.py \"#{install_dir}/agent/\""
  copy 'datadog-cert.pem', "#{install_dir}/agent/"

  mkdir "#{install_dir}/run/"

  if linux?
    # Configuration files
    mkdir '/etc/dd-agent'
    if redhat?
      copy 'packaging/centos/datadog-agent.init', '/etc/rc.d/init.d/datadog-agent'
    end

    if suse? || debian?
      if debian?
        sys_type = 'debian'
        systemd_directory = '/lib/systemd/system'
      elsif suse?
        sys_type = 'suse'
        systemd_directory = '/usr/lib/systemd/system'
      end
      copy "packaging/#{sys_type}/datadog-agent.init", '/etc/init.d/datadog-agent'
      mkdir systemd_directory
      copy 'packaging/debian/datadog-agent.service', "#{systemd_directory}/datadog-agent.service"
      copy 'packaging/debian/start_agent.sh', '/opt/datadog-agent/bin/start_agent.sh'
      command 'chmod 755 /opt/datadog-agent/bin/start_agent.sh'
    end

    # Use a supervisor conf with go-metro on 64-bit platforms only
    if ohai['kernel']['machine'] == 'x86_64'
      copy 'packaging/supervisor.conf', '/etc/dd-agent/supervisor.conf'
    else
      copy 'packaging/supervisor_32.conf', '/etc/dd-agent/supervisor.conf'
    end
    copy 'datadog.conf.example', '/etc/dd-agent/datadog.conf.example'
    copy 'conf.d', '/etc/dd-agent/'
    mkdir '/etc/dd-agent/checks.d/'
    command 'chmod 755 /etc/init.d/datadog-agent'
    touch '/usr/bin/dd-agent'

    # Remove the .pyc and .pyo files from the package and list them in a file
    # so that the prerm script knows which compiled files to remove
    command "echo '# DO NOT REMOVE/MODIFY - used by package removal tasks' > #{install_dir}/embedded/.py_compiled_files.txt"
    command "find #{install_dir}/embedded '(' -name '*.pyc' -o -name '*.pyo' ')' -type f -delete -print >> #{install_dir}/embedded/.py_compiled_files.txt"
  end

  if osx?
    env = {
      'PATH' => "#{install_dir}/embedded/bin/:#{ENV['PATH']}"
    }

    app_temp_dir = "#{install_dir}/agent/dist/Datadog Agent.app/Contents"
    app_temp_dir_escaped = "#{install_dir}/agent/dist/Datadog\\ Agent.app/Contents"
    pyside_build_dir =  "#{install_dir}/agent/build/bdist.macosx-10.5-intel/python2.7-standalone/app/collect/PySide"
    command_fix_shiboken = 'install_name_tool -change @rpath/libshiboken-python2.7.1.2.dylib'\
                      ' @executable_path/../Frameworks/libshiboken-python2.7.1.2.dylib '
    command_fix_pyside = 'install_name_tool -change @rpath/libpyside-python2.7.1.2.dylib'\
                      ' @executable_path/../Frameworks/libpyside-python2.7.1.2.dylib '

    # Command line tool
    copy 'packaging/osx/datadog-agent', "#{install_dir}/bin"
    command "chmod 755 #{install_dir}/bin/datadog-agent"

    # GUI
    copy 'packaging/datadog-agent/win32/install_files/guidata/images', "#{install_dir}/agent"
    copy 'win32/gui.py', "#{install_dir}/agent"
    copy 'win32/status.html', "#{install_dir}/agent"
    mkdir "#{install_dir}/agent/packaging"
    copy 'packaging/osx/app/*', "#{install_dir}/agent/packaging"

    command "cd #{install_dir}/agent && "\
            "#{install_dir}/embedded/bin/python #{install_dir}/agent/setup.py py2app"\
            ' && cd -', env: env
    # Time to patch the install, see py2app bug: (dependencies to system PySide)
    # https://bitbucket.org/ronaldoussoren/py2app/issue/143/resulting-app-mistakenly-looks-for-pyside
    copy "#{pyside_build_dir}/libshiboken-python2.7.1.2.dylib", "#{app_temp_dir}/Frameworks/libshiboken-python2.7.1.2.dylib"
    copy "#{pyside_build_dir}/libpyside-python2.7.1.2.dylib", "#{app_temp_dir}/Frameworks/libpyside-python2.7.1.2.dylib"

    command "chmod a+x #{app_temp_dir_escaped}/Frameworks/{libpyside,libshiboken}-python2.7.1.2.dylib"
    command "#{command_fix_shiboken} #{app_temp_dir_escaped}/Frameworks/libpyside-python2.7.1.2.dylib"
    command 'install_name_tool -change /usr/local/lib/QtCore.framework/Versions/4/QtCore '\
            '@executable_path/../Frameworks/QtCore.framework/Versions/4/QtCore '\
            "#{app_temp_dir_escaped}/Frameworks/libpyside-python2.7.1.2.dylib"
    command "#{command_fix_shiboken} #{app_temp_dir_escaped}/Resources/lib/python2.7/lib-dynload/PySide/QtCore.so"
    command "#{command_fix_shiboken} #{app_temp_dir_escaped}/Resources/lib/python2.7/lib-dynload/PySide/QtGui.so"
    command "#{command_fix_pyside} #{app_temp_dir_escaped}/Resources/lib/python2.7/lib-dynload/PySide/QtCore.so"
    command "#{command_fix_pyside} #{app_temp_dir_escaped}/Resources/lib/python2.7/lib-dynload/PySide/QtGui.so"

    # And finally
    command "cp -Rf #{install_dir}/agent/dist/Datadog\\ Agent.app #{install_dir}"

    # Clean GUI related things
    %w(build dist images gui.py status.html packaging Datadog_Agent.egg-info).each do |file|
      delete "#{install_dir}/agent/#{file}"
    end
    %w(py2app macholib modulegraph altgraph).each do |package|
      command "yes | #{install_dir}/embedded/bin/pip uninstall #{package}"
    end
    %w(pyside guidata spyderlib).each do |dependency_name|
      # Installed with `python setup.py install`, needs to be uninstalled manually
      command "cat #{install_dir}/embedded/#{dependency_name}-files.txt | xargs rm -rf \"{}\""
      delete "#{install_dir}/embedded/#{dependency_name}-files.txt"
    end

    # conf
    mkdir "#{install_dir}/etc"
    copy "packaging/osx/supervisor.conf", "#{install_dir}/etc/supervisor.conf"
    copy 'datadog.conf.example', "#{install_dir}/etc/datadog.conf.example"
    command "cp -R conf.d #{install_dir}/etc/"
    copy 'packaging/osx/com.datadoghq.Agent.plist.example', "#{install_dir}/etc/"
  end

  if windows?
    # Let's ship the usual (the copy DSL doesn't work on Windows)
    %w(checks.d checks dogstream utils win32 datadog-cert.pem).each do |original_path|
      command "XCOPY #{original_path} \"#{windows_safe_path(install_dir)}\\agent\\#{original_path}\" /YSHI"
    end

    # Let's ship images for our wonderful GUI too as well as an HTML template we can definitely
    # show off with...
    mkdir "dist/guidata"
    command "cp -R packaging/datadog-agent/win32/install_files/guidata/* dist/guidata"
    command "COPY packaging\\datadog-agent\\win32\\install_files\\ca-certificates.crt \"#{windows_safe_path(install_dir)}\\agent\""
    command "COPY packaging\\datadog-agent\\win32\\install_files\\license.rtf \"#{windows_safe_path(install_dir)}\""

    # Let's build an exe to launch as a service (and the GUI at the same time)
    # Note that it'd be really cool to build the service exe in Go because we wouldn't have to ship
    # Python with it and it would save several megabytes
    # Also if we could find a way to build GUIs (JS on Windows, Native on OSX ?) that don't require
    # any deps, I'm pretty sure we could go under 35 Megs on Windows
    command "COPY \"#{windows_safe_path(install_dir)}\\embedded\\Lib\\site-packages\\pywin32_system32\\pywintypes27.dll\" "\
            "\"#{windows_safe_path(install_dir)}\\embedded\\Lib\\site-packages\\win32\\\""
    command "COPY \"#{windows_safe_path(install_dir)}\\embedded\\Lib\\site-packages\\pywin32_system32\\pythoncom27.dll\" "\
            "\"#{windows_safe_path(install_dir)}\\embedded\\Lib\\site-packages\\win32\\\""
    command "COPY \"#{windows_safe_path(install_dir)}\\embedded\\Lib\\site-packages\\pywin32_system32\\pythoncomloader27.dll\" "\
            "\"#{windows_safe_path(install_dir)}\\embedded\\Lib\\site-packages\\win32\\\""

    command "\"#{windows_safe_path(install_dir)}\\embedded\\python\" setup.py py2exe"
    command 'XCOPY dist ..\\OMNIBUS_EXTRA_PACKAGE_FILES\\DIST /YSHI'
    command "COPY win32\\status.html ..\\OMNIBUS_EXTRA_PACKAGE_FILES\\DIST\\status.html"
    # The GUI also needs to have the certificate in its folder to send e-mails via Flare
    command "COPY datadog-cert.pem ..\\OMNIBUS_EXTRA_PACKAGE_FILES\\DIST\\datadog-cert.pem"

    # Let's move the service file out of that directory so that it's not processed by heat and we
    # can add it manually, as a service executable, in our source.wxs file as if nothing happened
    command 'MOVE ..\\OMNIBUS_EXTRA_PACKAGE_FILES\\DIST\\ddagent.exe .\\ddagent.exe'

    # This uses part f our fork of Omnibus. We copy "extra_package_files" that we want here
    # so that they can be harvested by heat, and shipped in the MSI by light
    mkdir '..\\OMNIBUS_EXTRA_PACKAGE_FILES\\EXAMPLECONFSLOCATION'
    mkdir '..\\OMNIBUS_EXTRA_PACKAGE_FILES\\APPLICATIONDATADIRECTORY'
    command 'XCOPY conf.d ..\\OMNIBUS_EXTRA_PACKAGE_FILES\\EXAMPLECONFSLOCATION /YSHI'
    command 'COPY packaging\\datadog-agent\\win32\\install_files\\datadog_win32.conf '\
            '..\\OMNIBUS_EXTRA_PACKAGE_FILES\\APPLICATIONDATADIRECTORY\\datadog.conf.example'

    # Weight-loss surgery
    command "\"#{windows_safe_path(install_dir)}\\embedded\\Scripts\\pip.exe\" uninstall -y PySide"
    command "CHDIR \"#{windows_safe_path(install_dir)}\" & del /Q /S *.pyc"
    command "CHDIR \"#{windows_safe_path(install_dir)}\" & del /Q /S *.chm"
  end
end
