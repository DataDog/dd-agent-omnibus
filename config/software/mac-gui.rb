require './lib/ostools.rb'

name 'mac-gui'
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

build do
  ship_license 'https://raw.githubusercontent.com/DataDog/dd-agent/master/LICENSE'

  mkdir "#{install_dir}/agent"

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

    block do # defer in a block to allow getting the project's build version
      erb source: "Info.plist.erb",
          dest: "#{app_temp_dir}/Info.plist",
          mode: 0755,
          vars: { version: project.build_version, year: Time.now.year, executable: "gui" }
    end

    mkdir "#{app_temp_dir}/MacOS"
    command 'cd packaging/osx/gui && swiftc -O -target "x86_64-apple-macosx10.10" -static-stdlib Sources/* -o gui && cd ../../..'
    copy "packaging/osx/gui/gui", "#{app_temp_dir}/MacOS/"
  end
end
