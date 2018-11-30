require './lib/ostools.rb'

name 'datadog-agent-integrations'

dependency 'pip'
dependency 'datadog-agent'

if linux?
  dependency 'unixodbc'
end

unless windows?
  dependency 'libkrb5'
end

relative_path 'integrations-core'

PIPTOOLS_VERSION = "2.0.2"
WHEELS_VERSION = "0.30.0"
# dependencies for pip-tools. If any of these is an agent requirement
# they will not be uninstalled (ie. six). But keeping the list exhaustive.
UNINSTALL_PIPTOOLS_DEPS = ['six', 'click', 'first', 'pip-tools']

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

# Skip installing checks that aren't consumer facing
blacklist = [
  'datadog_checks_base',           # namespacing package for wheels (NOT AN INTEGRATION)
  'datadog_checks_dev',            # developer tooling for working on integrations (NOT AN INTEGRATION)
  'datadog_checks_tests_helper',   # Testing and Development package, (NOT AN INTEGRATION)
]

python_lib_path = File.join(install_dir, "embedded", "lib", "python2.7", "site-packages")
whitelist_file "#{python_lib_path}"

build do
  checks = []

  # build do cannot have fully dynamic actions in it
  # Dynamic actions must be put inside of "block do"
  # since most of this is dynamic, I'll wrap the whole thing in `block do`
  block 'prepare python environment + integrations' do
    # Grab all the checks
    checks = Dir.glob("#{project_dir}/*/")

    # Unix build environment
    unix_build_env = {
      "CFLAGS" => "-I#{install_dir}/embedded/include",
      "CXXFLAGS" => "-I#{install_dir}/embedded/include",
      "LDFLAGS" => "-L#{install_dir}/embedded/lib",
      "LD_RUN_PATH" => "#{install_dir}/embedded/lib",
      "PATH" => "#{install_dir}/embedded/bin:#{ENV['PATH']}",
    }

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
    all_reqs_file.puts "wheel==#{WHEELS_VERSION} --hash=sha256:e721e53864f084f956f40f96124a74da0631ac13fbbd1ba99e8e2b5e9cafdf64"\
        " --hash=sha256:9515fe0a94e823fd90b08d22de45d7bde57c90edce705b22f5e1ecf7e1b653c8"
    all_reqs_file.close

    # Set frozen requirements (save to var, and to file)
    # HACK: we need to do this like this due to the well known issues with omnibus 
    # runtime requirements.  
    if windows?
      freeze_mixin = shellout!("#{windows_safe_path(install_dir)}\\embedded\\Scripts\\pip.exe freeze")
      frozen_agent_reqs = freeze_mixin.stdout
    else
      freeze_mixin = shellout!("#{install_dir}/embedded/bin/pip freeze")
      frozen_agent_reqs = freeze_mixin.stdout
    end
    pip "freeze > #{install_dir}/agent_requirements.txt"

    # Install all the requirements
    if windows?
      pip "install pip-tools==#{PIPTOOLS_VERSION}"
      pip "install -r #{project_dir}/check_requirements.txt"
    else
      pip "install pip-tools==#{PIPTOOLS_VERSION}", :env => unix_build_env
      pip "install -vvv -r #{project_dir}/check_requirements.txt", :env => unix_build_env
    end

    # Windows pip workaround to support globs
    python_bin = "\"#{windows_safe_path(install_dir)}\\embedded\\python.exe\""
    python_pip_no_deps = "pip install --no-deps #{windows_safe_path(project_dir)}"
    python_pip_reqs = "pip install -c #{windows_safe_path(install_dir)}\\agent_requirements.txt --require-hashes -r"
    python_pip_uninstall = "pip uninstall -y"

    # Install the static environment requirements that the Agent and all checks will use
    if windows?
      command("#{python_bin} -m #{python_pip_no_deps}\\datadog_checks_base")
      command("#{python_bin} -m piptools compile --generate-hashes --output-file #{windows_safe_path(project_dir)}\\static_requirements.txt #{windows_safe_path(project_dir)}\\datadog_checks_base\\datadog_checks\\base\\data\\agent_requirements.in")
    else
      pip "install -vvv --no-deps .", :env => unix_build_env, :cwd => "#{project_dir}/datadog_checks_base"
      command("#{install_dir}/embedded/bin/python -m piptools compile --generate-hashes --output-file #{project_dir}/static_requirements.txt #{project_dir}/datadog_checks_base/datadog_checks/base/data/agent_requirements.in")
    end

    # Uninstall the deps that pip-compile installs so we don't include them in the final artifact
    UNINSTALL_PIPTOOLS_DEPS.each do |dep|
      re = Regexp.new("^#{dep}==").freeze
      if not re.match frozen_agent_reqs
        if windows?
          command("#{python_bin} -m #{python_pip_uninstall} #{dep}")
        else
          pip "uninstall -y #{dep}"
        end
      end
    end

    # install static-environment requirements
    if windows?
      command("#{python_bin} -m #{python_pip_reqs} #{windows_safe_path(project_dir)}\\static_requirements.txt")
    else
      pip "install -vvv -c #{install_dir}/agent_requirements.txt --require-hashes -r #{project_dir}/static_requirements.txt", :env => unix_build_env
    end


    # loop through checks and install each without their dependencies
    # we rely on a static Agent environment that was built above. 
    checks.each do |check|
      next if blacklist.include?(check)

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
      if File.exists? "#{project_dir}/#{check}/datadog_checks/#{check}/data/conf.yaml.example"
        copy "#{project_dir}/#{check}/datadog_checks/#{check}/data/conf.yaml.example", "#{conf_directory}/#{check}.yaml.example"
      end
      # Copy the default config, if it exists
      if File.exists? "#{project_dir}/#{check}/datadog_checks/#{check}/data/conf.yaml.default"
        copy "#{project_dir}/#{check}/datadog_checks/#{check}/data/conf.yaml.default", "#{conf_directory}/#{check}.yaml.default"
      end

      # We don't have auto_conf on windows yet
      unless windows?
        if File.exists? "#{project_dir}/#{check}/datadog_checks/#{check}/data/auto_conf.yaml"
          copy "#{project_dir}/#{check}/datadog_checks/#{check}/data/auto_conf.yaml", "#{conf_directory}/auto_conf/#{check}.yaml"
        end
      end

      File.file?("#{project_dir}/#{check}/setup.py") || next

      # Installing each integration with no deps because each integration depends
      # only datadog_checks_base. All integrations-core requirements are now in requirements.in in the repo
      # We won't install deps here to help ensure that no new dependencies sneak into the setup.py during the PR review process. 
      if windows?
        command("#{python_bin} -m #{python_pip_no_deps}\\#{check}")
      else
        pip "install --no-deps .", :env => unix_build_env, :cwd => "#{project_dir}/#{check}"
      end
    end
    if windows?
        command "CHDIR #{install_dir} & del /Q /S *.pyc"
        command "CHDIR #{install_dir} & del /Q /S *.chm"
    end
  end
end
