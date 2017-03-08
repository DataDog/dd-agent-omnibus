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

integrations_core_branch = ENV['INTEGRATION_CORE_BRANCH']
if integrations_core_branch.nil? || integrations_core_branch.empty?
  default_version 'master'
else
  default_version integrations_core_branch
end

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

    # Open the concatenated checks requirements file
    # We're going to store it with the agent install
    all_reqs_file_path = "/check_requirements.txt"
    if File.exist?(all_reqs_file_path)
      all_reqs_file = File.open(all_reqs_file_path, 'w+')
    else
      all_reqs_file = File.new(all_reqs_file_path, 'w+')
    end

    # all_reqs_file = File.open("#{install_dir}/agent/check_requirements.txt", 'w+')

    # The conf directory is different on every system
    if linux?
      conf_directory = "/etc/dd-agent/conf.d"
    elsif osx?
      conf_directory = "#{install_dir}/etc"
    elsif windows?
      conf_directory = "../../extra_package_files/EXAMPLECONFSLOCATION"
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
        manifest['supported_os'].include?('osx') || next
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

      if File.exists?("#{project_dir}/#{check}/requirements.txt") && !manifest['use_omnibus_reqs']
        reqs = File.open("#{project_dir}/#{check}/requirements.txt", 'r').read
        reqs.each_line do |line|
          if line[0] != '#'
            all_reqs_file.puts line
          end
        end
      end
    end

    # Close the checks requirements file
    all_reqs_file.close

  pip_cmd = "install --install-option=\"--install-scripts=#{windows_safe_path(install_dir)}/bin\" -c #{install_dir}/agent/requirements.txt -r /check_requirements.txt"
  if windows?
    inst_cmd = "#{windows_safe_path(install_dir)}\\embedded\\scripts\\pip.exe " + pip_cmd
    command inst_cmd
  else
    build_env = {
      "LD_RUN_PATH" => "#{install_dir}/embedded/lib",
      "PATH" => "/#{install_dir}/embedded/bin:#{ENV['PATH']}",
    }
    command "pip #{pip_cmd}", :env => build_env
  end

    copy '/check_requirements.txt', "#{install_dir}/agent/"
  end
end
