require 'json'
require 'ohai'

@ohai = Ohai::System.new.tap { |o| o.all_plugins(%w{platform}) }.data

def linux?()
  %w(rhel debian fedora suse gentoo slackware arch exherbo).include? @ohai['platform_family']
end

def osx?()
  @ohai['platform_family'] == 'mac_os_x'
end

def windows?()
  @ohai['platform_family'] == 'windows'
end


if windows?
  PROJECT_DIR='c:\dd-agent-omnibus'
  FSROOT="/c/"
else
  PROJECT_DIR='/dd-agent-omnibus'
  FSROOT="/"
end

namespace :agent do
  desc 'Cleanup generated files'
  task :clean do |t|
    puts "Clean up generated files"
    unless windows?
      sh "rm -rf #{FSROOT}var/cache/omnibus/pkg/*"
      sh "rm -f #{FSROOT}etc/init.d/datadog-agent"
      sh "rm -rf #{FSROOT}etc/dd-agent"
    end
    sh "rm -rf #{FSROOT}opt/datadog-agent"
    t.reenable
  end

  desc 'Pull the integrations repo'
  task :'pull-integrations' do
    integration_branch = ENV['INTEGRATION_BRANCH'] || 'master'

    # FSROOT is "/" on linux, "c:\" on windows.  Let's not clobber the filesystem
    # if someone forgets to set INTEGRATIONS_REPO
    raise 'INTEGRATIONS_REPO not set!' unless ENV['INTEGRATIONS_REPO']
    sh "rm -rf #{FSROOT}#{ENV['INTEGRATIONS_REPO']}"

    sh "git clone https://github.com/DataDog/#{ENV['INTEGRATIONS_REPO']}.git /#{ENV['INTEGRATIONS_REPO']} || true"
    sh "cd /#{ENV['INTEGRATIONS_REPO']} && git checkout #{integration_branch}"
    sh "cd /#{ENV['INTEGRATIONS_REPO']} && git fetch --all"
    sh "cd /#{ENV['INTEGRATIONS_REPO']} && git checkout dd-check-#{ENV['INTEGRATION']}-#{integration_branch} || git checkout #{integration_branch}"
    sh "cd /#{ENV['INTEGRATIONS_REPO']} && git reset --hard"
  end

  desc 'Build an integration'
  task :'build-integration' do
    Rake::Task["agent:clean"].invoke
    Rake::Task["env:import-rpm-key"].invoke
    Rake::Task["agent:pull-integrations"].invoke
    build_all = ENV.has_key?('BUILD_ALL_INTEGRATIONS') && ENV['BUILD_ALL_INTEGRATIONS'] == '1' || !ENV.has_key?('INTEGRATION')
    if build_all || ENV['INTEGRATION'].empty? || !ENV['INTEGRATION']
      Rake::Task["agent:build-all-integrations"].invoke
    elsif ENV['INTEGRATION']
      checks = ENV['INTEGRATION'].split(',')
      checks.each do |check|
        prepare_and_execute_build(check)
      end
    end
  end

  desc 'Build all integrations'
  task :'build-all-integrations' do
    checks = Dir.glob("/#{ENV['INTEGRATIONS_REPO']}/*/")
    if ENV['SKIP_INTEGRATION']
      skip_checks = ENV['SKIP_INTEGRATION'].split(',')
    else
      skip_checks = []
    end
    checks.each do |check|
      check.slice! "/#{ENV['INTEGRATIONS_REPO']}/"
      check.slice! "/"
      unless skip_checks.include? check
        prepare_and_execute_build(check)
        Rake::Task["agent:clean"].invoke
      end
    end
  end
end

namespace :env do
  desc 'Import signing RPM key'
  task :'import-rpm-key' do
    # If an RPM_SIGNING_PASSPHRASE has been passed, let's import the signing key
    if ENV.has_key?('RPM_SIGNING_PASSPHRASE') and not ENV['RPM_SIGNING_PASSPHRASE'].empty?
      sh "if [ \"$RPM_SIGNING_PASSPHRASE\" ]; then gpg --import /keys/RPM-SIGNING-KEY.private; fi"
    end
  end
end

def prepare_and_execute_build(integration, dont_error_on_build: false)
  sh "cd #{PROJECT_DIR} && bundle update"
  puts "building integration #{integration}"

  manifest = JSON.parse(File.read("/#{ENV['INTEGRATIONS_REPO']}/#{integration}/manifest.json"))
  # The manifest should always have a version
  integration_version = manifest['version']
  if linux?
    manifest['supported_os'].include?('linux') || return
  elsif windows?
    manifest['supported_os'].include?('windows') || return
  elsif osx?
    manifest['supported_os'].include?('osx') || return
  end

  header = erb_header({
    'name' => "#{integration}",
    'version' => "#{integration_version}",
    'build_iteration' => "#{ENV['BUILD_ITERATION']}",
    'integrations_repo' => "#{ENV['INTEGRATIONS_REPO']}",
    'guid' => "#{manifest['guid']}",
    'description' => "#{manifest['description']}"
  })

  #`(echo '#{header}' && cat #{PROJECT_DIR}/resources/datadog-integrations/project.rb.erb) | erb > #{PROJECT_DIR}/config/projects/dd-check-#{integration}.rb`
  sh "(echo \"#{header}\" && cat #{PROJECT_DIR}/resources/datadog-integrations/project.rb.erb) | erb > #{PROJECT_DIR}/config/projects/dd-check-#{integration}.rb"

  header = erb_header({
    'name' => "#{integration}",
    'project_dir' => "#{PROJECT_DIR}",
    'integrations_repo' => "#{ENV['INTEGRATIONS_REPO']}"
  })

  sh "(echo \"#{header}\" && cat #{PROJECT_DIR}/resources/datadog-integrations/software.rb.erb) | erb > #{PROJECT_DIR}/config/software/dd-check-#{integration}-software.rb"

  if windows?
    FileUtils.mkdir_p("#{PROJECT_DIR}/resources/dd-check-#{integration}/msi")
    FileUtils.cp_r("#{PROJECT_DIR}/resources/datadog-integrations/msi", "#{PROJECT_DIR}/resources/dd-check-#{integration}")
  end

  if windows?
    sh "cd #{PROJECT_DIR} && bundle exec omnibus --version"
    build_cmd = "cd #{PROJECT_DIR} && bundle exec omnibus build --log-level debug dd-check-#{integration}"
  else
    sh "cd #{PROJECT_DIR} && omnibus --version"
    build_cmd = "cd #{PROJECT_DIR} && bin/omnibus build dd-check-#{integration} --output_manifest=false"
  end

  if dont_error_on_build
    build_cmd += " || true"
  end
  sh build_cmd
end

def erb_header(variables)
  # ERB does not support setting template variables on the command line
  # this method generates a header usable by a ERB file
  out = ""
  variables.each do |key, value|
    out += "<% #{key}='#{value}' %>"
  end
  out
end
