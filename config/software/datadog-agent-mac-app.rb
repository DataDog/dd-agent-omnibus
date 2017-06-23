name 'datadog-agent-mac-app'

description "Build mac agent GUI and generate app manifests"

dependency "datadog-agent"

# This needs to be done in a separate software because we need to know the Agent Version to build some
# parts of the app, and `project.build_version` is populated only once the software that the project
# takes its version from (i.e. `datadog-agent`) has finished building
build do
    app_temp_dir = "#{install_dir}/Datadog Agent.app/Contents"
    mkdir "#{app_temp_dir}/Resources"
    copy 'packaging/osx/app/Agent.icns', "#{app_temp_dir}/Resources/"

    mkdir "#{app_temp_dir}/MacOS"
    command 'cd packaging/osx/gui && swiftc -O -target "x86_64-apple-macosx10.10" -static-stdlib Sources/* -o gui && cd ../../..'
    copy "packaging/osx/gui/gui", "#{app_temp_dir}/MacOS/"

    block do # defer in a block to allow getting the project's build version
      app_temp_dir = "#{install_dir}/Datadog Agent.app/Contents"
      erb source: "Info.plist.erb",
          dest: "#{app_temp_dir}/Info.plist",
          mode: 0755,
          vars: { version: project.build_version, year: Time.now.year, executable: "gui" }
    end
end
