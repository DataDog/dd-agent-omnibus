require './lib/ostools.rb'

name 'datadog-agent'
always_build true

local_agent_repo = ENV['LOCAL_AGENT_REPO']
if local_agent_repo.nil? || local_agent_repo.empty?
  source git: 'https://github.com/DataDog/dd-agent.git', always_fetch_tags: true
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

dependency 'agent-deps'

build do
  ship_license 'https://raw.githubusercontent.com/DataDog/dd-agent/master/LICENSE'

  mkdir  "#{install_dir}/agent/"

  # Agent code
  mkdir "#{install_dir}/agent/checks.d"
  copy 'checks.d', "#{install_dir}/agent/"

  copy 'checks', "#{install_dir}/agent/"
  copy 'dogstream', "#{install_dir}/agent/"
  copy 'utils', "#{install_dir}/agent/"

  copy 'requirements.txt', "#{install_dir}/agent/"

  command "cp *.py \"#{install_dir}/agent/\""
  copy 'datadog-cert.pem', "#{install_dir}/agent/"

  mkdir "#{install_dir}/run/"
  mkdir "#{install_dir}/bin/"

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
    mkdir "/etc/dd-agent/conf.d/auto_conf"
    copy 'conf.d', '/etc/dd-agent/'

    mkdir '/etc/dd-agent/checks.d/'
    command 'chmod 755 /etc/init.d/datadog-agent'
    touch '/usr/bin/dd-agent'
  end

  if osx?
    env = {
      'PATH' => "#{install_dir}/embedded/bin/:#{ENV['PATH']}"
    }

    # Command line tool
    copy 'packaging/osx/datadog-agent', "#{install_dir}/bin"
    command "chmod 755 #{install_dir}/bin/datadog-agent"

    # conf
    mkdir "#{install_dir}/etc"
  
    copy "packaging/osx/supervisor.conf", "#{install_dir}/etc/supervisor.conf"
    copy 'datadog.conf.example', "#{install_dir}/etc/datadog.conf.example"
    mkdir "#{install_dir}/etc/conf.d/auto_conf"
    command "cp -R conf.d #{install_dir}/etc/"
    copy 'packaging/osx/com.datadoghq.Agent.plist.example', "#{install_dir}/etc/"

    # GUI
    app_temp_dir = "#{install_dir}/Datadog Agent.app/Contents"
    mkdir "#{app_temp_dir}/Resources"
    copy 'packaging/osx/app/Agent.icns', "#{app_temp_dir}/Resources/"

    mkdir "#{app_temp_dir}/MacOS"
    command 'cd packaging/osx/gui && swiftc -O -target "x86_64-apple-macosx10.10" -static-stdlib Sources/*.swift -o gui && cd ../../..'
    copy "packaging/osx/gui/gui", "#{app_temp_dir}/MacOS/"
    copy "packaging/osx/gui/Sources/agent.png", "#{app_temp_dir}/MacOS/"
  end

  unless windows?
    # The file below is touched by software builds that don't put anything in the installation
    # directory (libgcc right now) so that the git_cache gets updated let's remove it from the
    # final package
    delete "#{install_dir}/uselessfile"
  end

  if windows?
    # Let's ship win32
    copy 'win32', "#{install_dir}/agent"

    # Let's ship images for our wonderful GUI too as well as an HTML template we can definitely
    # show off with...
    mkdir "dist"
    copy "packaging/datadog-agent/win32/install_files/guidata", "dist"
    copy "packaging/datadog-agent/win32/install_files/ca-certificates.crt", "#{install_dir}/agent/"
    copy "packaging/datadog-agent/win32/install_files/license.rtf", "#{install_dir}/license.rtf"

    # Let's build an exe to launch as a service (and the GUI at the same time)
    # Note that it'd be really cool to build the service exe in Go because we wouldn't have to ship
    # Python with it and it would save several megabytes
    # Also if we could find a way to build GUIs (JS on Windows, Native on OSX ?) that don't require
    # any deps, I'm pretty sure we could go under 35 Megs on Windows
    %w(pywintypes27 pythoncom27 pythoncomloader27).each do |name|
      copy "#{install_dir}/embedded/Lib/site-packages/pywin32_system32/#{name}.dll",
           "#{install_dir}/embedded/Lib/site-packages/win32"
    end

    # Let's "compile" the GUI and the service
    command "#{install_dir}/embedded/python setup.py py2exe"

    copy "dist", "#{install_dir}"
    copy "win32/status.html", "#{install_dir}/dist/status.html"
    # Avoid shipping twice ddagent.exe
    delete "#{install_dir}/dist/ddagent.exe"
    # The GUI also needs to have the certificate in its folder to send flares
    copy "datadog-cert.pem", "#{install_dir}/dist/datadog-cert.pem"

    #make (yet another) copy of the the microsoft DLLS in the embedded DLLS
    # directory. For some reason, it's not using the correct binary search
    # path, and the compiled DLLs fail to load.  Appears to only be a problem
    # on Win2k8, on later OSes that CRT is part of the OS'
    copy "#{install_dir}/dist/msvc*.dll", "#{install_dir}/embedded/DLLs"
    copy "#{install_dir}/dist/Microsoft*.manifest", "#{install_dir}/embedded/DLLs"

    # Special directories, which won't be installed at the same place than others (ProgramData)
    mkdir "../../extra_package_files"
    mkdir "../../extra_package_files/EXAMPLECONFSLOCATION"

    # This uses part of our fork of Omnibus. We copy "extra_package_files" that we want here
    # so that they can be harvested by heat, and shipped in the MSI by light
    copy "conf.d/*", "../../extra_package_files/EXAMPLECONFSLOCATION"

    # Weight-loss surgery
    command "#{install_dir}/embedded/Scripts/pip.exe uninstall -y PySide"
    command "CHDIR #{install_dir} & del /Q /S *.pyc"
    command "CHDIR #{install_dir} & del /Q /S *.chm"
  end
end
