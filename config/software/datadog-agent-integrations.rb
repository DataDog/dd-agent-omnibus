require './lib/ostools.rb'

name 'datadog-agent-integrations'

dependency 'pip'
dependency 'datadog-agent'

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

python_lib_path = File.join(install_dir, "embedded", "lib", "python2.7", "site-packages")
whitelist_file "#{python_lib_path}"

build do
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

    all_reqs_file = File.open("#{project_dir}/check_requirements.txt", 'w+')
    # Manually add "core" dependencies that are not listed in the checks requirements
    # FIX THIS these dependencies have to be grabbed from somewhere
    all_reqs_file.puts "wheel==0.30.0 --hash=sha256:e721e53864f084f956f40f96124a74da0631ac13fbbd1ba99e8e2b5e9cafdf64"\
        " --hash=sha256:9515fe0a94e823fd90b08d22de45d7bde57c90edce705b22f5e1ecf7e1b653c8"

    all_reqs_file.close

    # Install all the requirements
    if windows?
      pip "install -r #{project_dir}/check_requirements.txt"
    else
      build_env = {
        "LD_RUN_PATH" => "#{install_dir}/embedded/lib",
        "PATH" => "#{install_dir}/embedded/bin:#{ENV['PATH']}",
      }
      pip "install -r #{project_dir}/check_requirements.txt", :env => build_env
    end

    # Set frozen requirements
    pip "freeze > #{install_dir}/agent_requirements.txt"

    # Windows pip workaround to support globs
    python_bin = "\"#{windows_safe_path(install_dir)}\\embedded\\python.exe\""
    python_pip = "\"import pip, glob; pip.main(['install', '-c', '#{install_dir}/agent_requirements.txt'] + glob.glob('*.whl'))\""

    if windows?
      pip "wheel --no-deps .", :cwd => "#{project_dir}/datadog-checks-base"
      command("#{python_bin} -c #{python_pip}", cwd: "#{project_dir}/datadog-checks-base")
    else
      build_env = {
        "LD_RUN_PATH" => "#{install_dir}/embedded/lib",
        "PATH" => "#{install_dir}/embedded/bin:#{ENV['PATH']}",
      }
      pip "wheel --no-deps .", :env => build_env, :cwd => "#{project_dir}/datadog-checks-base"
      pip "install -c #{install_dir}/agent_requirements.txt *.whl", :env => build_env, :cwd => "#{project_dir}/datadog-checks-base"
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

      File.file?("#{project_dir}/#{check}/setup.py") || next
      if windows?
        pip "wheel --no-deps .", :cwd => "#{project_dir}/#{check}"
        command("#{python_bin} -c #{python_pip}", cwd: "#{project_dir}/#{check}")
      else
        build_env = {
          "LD_RUN_PATH" => "#{install_dir}/embedded/lib",
          "PATH" => "#{install_dir}/embedded/bin:#{ENV['PATH']}",
        }
        pip "wheel --no-deps .", :env => build_env, :cwd => "#{project_dir}/#{check}"
        pip "install -c #{install_dir}/agent_requirements.txt *.whl", :env => build_env, :cwd => "#{project_dir}/#{check}"
      end
    end
  end
end
