require './lib/ostools.rb'

name 'datadog-agent-integrations'

dependency 'pip'
dependency 'datadog-agent'
dependency 'integration-deps'

relative_path 'integrations-core'

# The only integrations that will be packaged with the agent
# are the ones that are officiallly supported.
local_integrations_core_repo = ENV['LOCAL_INTEGRATIONS_CORE_REPO']
if local_integrations_core_repo.nil? || local_integrations_core_repo.empty?
  source git: 'https://github.com/DataDog/integrations-core.git'
else
  # For local development
  source path: ENV['LOCAL_INTEGRATIONS_CORE_REPO']
end

integrations_core_branch = ENV['INTEGRATIONS_CORE_BRANCH']
if integrations_core_branch.nil? || integrations_core_branch.empty?
  default_version 'master'
else
  default_version integrations_core_branch
end

blacklist = [
  'datadog-checks-base',  # namespacing package for wheels (NOT AN INTEGRATION)
]

build do
  # Agent code
  mkdir  "#{install_dir}/agent/checks.d"

  checks = []

  # build do cannot have fully dynamic actions in it
  # Dynamic actions must be put inside of "block do"
  # since most of this is dynamic, I'll wrap the whole thing in `block do`
  block do
    # Grab all the checks
    checks = Dir.glob("#{project_dir}/*/")

    # The conf directory is different on every system
    if linux?
      conf_directory = "/etc/dd-agent/conf.d"
    elsif osx?
      conf_directory = "#{install_dir}/etc"
    elsif windows?
      conf_directory = "../../extra_package_files/EXAMPLECONFSLOCATION"
    end

    if windows?
      pip "wheel --no-deps .", :cwd => "#{project_dir}/datadog-checks-base"
      Dir.glob("#{project_dir}\\datadog-base\\*.whl").each do |wheel_path|
        whl_file = wheel_path.split('/').last
        pip "install #{whl_file}", :cwd => "#{project_dir}/datadog-checks-base"
      end
    else
      build_env = {
        "LD_RUN_PATH" => "#{install_dir}/embedded/lib",
        "PATH" => "#{install_dir}/embedded/bin:#{ENV['PATH']}",
      }
      pip "wheel --no-deps .", :env => build_env, :cwd => "#{project_dir}/datadog-checks-base"
      pip "install *.whl", :env => build_env, :cwd => "#{project_dir}/datadog-checks-base"
    end

    # loop through them
    checks.each do |check|
      # Only use the parts of the filename we need
      check.slice! "#{project_dir}/"
      check.slice! "/"

      # Check the manifest to be sure that this check is enabled on this system
      # or skip this iteration
      manifest_file_path = "#{project_dir}/#{check}/manifest.json"

      # If there is no manifest file, then we should assume the folder does not
      # contain a working check and move onto the next
      File.exist?(manifest_file_path) || next

      manifest = JSON.parse(File.read(manifest_file_path))
      if linux?
        manifest['supported_os'].include?('linux') || next
      elsif windows?
        manifest['supported_os'].include?('windows') || next
      elsif osx?
        manifest['supported_os'].include?('mac_os') || next
      end

      # Copy the checks over
      if File.exists? "#{project_dir}/#{check}/check.py"
        copy "#{project_dir}/#{check}/check.py", "#{install_dir}/agent/checks.d/#{check}.py"
      end

      # Copy the check config to the conf directories
      if File.exists? "#{project_dir}/#{check}/conf.yaml.example"
        copy "#{project_dir}/#{check}/conf.yaml.example", "#{conf_directory}/#{check}.yaml.example"
      end
      # Copy the default config, if it exists
      if File.exists? "#{project_dir}/#{check}/conf.yaml.default"
        copy "#{project_dir}/#{check}/conf.yaml.default", "#{conf_directory}/#{check}.yaml.default"
      end

      # We don't have auto_conf on windows yet
      unless windows?
        if File.exists? "#{project_dir}/#{check}/auto_conf.yaml"
          copy "#{project_dir}/#{check}/auto_conf.yaml", "#{conf_directory}/auto_conf/#{check}.yaml"
        end
      end

      File.file?("#{check_dir}/setup.py") || next
      if windows?
        pip "wheel --no-deps .", :cwd => "#{project_dir}/#{check}"
        Dir.glob("#{project_dir}\\#{check}\\*.whl").each do |wheel_path|
          whl_file = wheel_path.split('/').last
          pip "install #{whl_file}", :cwd => "#{project_dir}/#{check}"
        end
      else
        build_env = {
          "LD_RUN_PATH" => "#{install_dir}/embedded/lib",
          "PATH" => "#{install_dir}/embedded/bin:#{ENV['PATH']}",
        }
        pip "wheel --no-deps .", :env => build_env, :cwd => "#{project_dir}/#{check}"
        pip "install *.whl", :env => build_env, :cwd => "#{project_dir}/#{check}"
      end

      # if File.exists?("#{project_dir}/#{check}/requirements.txt") && !manifest['use_omnibus_reqs']
      #   reqs = File.open("#{project_dir}/#{check}/requirements.txt", 'r').read
      #   reqs.each_line do |line|
      #     if line[0] != '#'
      #       all_reqs_file.puts line
      #     end
      #   end
      # end
    end

    # Close the checks requirements file
    # all_reqs_file.close

    # build_env = {
    #   "LD_RUN_PATH" => "#{install_dir}/embedded/lib",
    #   "PATH" => "/#{install_dir}/embedded/bin:#{ENV['PATH']}",
    # }
    # pip "install -c #{install_dir}/agent/requirements.txt -r /check_requirements.txt", env: build_env

    # copy '/check_requirements.txt', "#{install_dir}/agent/"
  end
end
