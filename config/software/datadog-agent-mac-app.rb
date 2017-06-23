name 'datadog-agent-mac-app'

description "Generate mac app manifest"

dependency "datadog-agent"

# This needs to be done in a separate software because we need to know the Agent Version to build the app
# manifest, and `project.build_version` is populated only once the software that the project
# takes its version from (i.e. `datadog-agent`) has finished building
build do
    block do # defer in a block to allow getting the project's build version
      app_temp_dir = "#{install_dir}/Datadog Agent.app/Contents"
      erb source: "Info.plist.erb",
          dest: "#{app_temp_dir}/Info.plist",
          mode: 0755,
          vars: { version: project.build_version, year: Time.now.year, executable: "gui" }
    end
end
