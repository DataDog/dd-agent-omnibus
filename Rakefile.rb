require 'json'
require 'ohai'

PROJECT_DIR='/dd-agent-omnibus'

@ohai = Ohai::System.new.tap { |o| o.all_plugins(%w{platform}) }.data

namespace :agent do
  desc 'Cleanup generated files'
  task :clean do |t|
    puts "Clean up generated files"
    sh "rm -rf /var/cache/omnibus/pkg/*"
    sh "rm -f /etc/init.d/datadog-agent"
    sh "rm -rf /etc/dd-agent"
    sh "rm -rf /opt/datadog-agent"
    t.reenable
  end

  desc 'Pull the integrations repo'
  task :'pull-integrations' do
    integration_branch = ENV['INTEGRATION_BRANCH'] || 'master'

    sh "rm -rf /#{ENV['INTEGRATIONS_REPO']}"
    sh "git clone https://github.com/DataDog/#{ENV['INTEGRATIONS_REPO']}.git /#{ENV['INTEGRATIONS_REPO']} || true"
    sh "cd /#{ENV['INTEGRATIONS_REPO']} && git checkout #{integration_branch}"
    sh "cd /#{ENV['INTEGRATIONS_REPO']} && git fetch --all"
    sh "cd /#{ENV['INTEGRATIONS_REPO']} && git checkout master"
    sh "cd /#{ENV['INTEGRATIONS_REPO']} && git reset --hard"
  end

  desc 'Build an integration'
  task :'build-integration' do
    Rake::Task["agent:clean"].invoke
    Rake::Task["env:import-rpm-key"].invoke
    Rake::Task["agent:pull-integrations"].invoke
    if ENV['BUILD_ALL_INTEGRATIONS'] || !ENV['INTEGRATION']
      Rake::Task["agent:build-all-integrations"].invoke
    elsif ENV['INTEGRATIONS']
      checks = ENV['INTEGRATIONS'].split(',')
      checks.each do |check|
        ENV['INTEGRATION'] = check
        prepare_and_execute_build(check)
      end
    else
      prepare_and_execute_build(check)
    end
  end

  desc 'Build all integrations'
  task :'build-all-integrations' do
    checks = Dir.glob("/#{ENV['INTEGRATIONS_REPO']}/*/")
    checks.each do |check|
      check.slice! "/#{ENV['INTEGRATIONS_REPO']}/"
      check.slice! "/"
      prepare_and_execute_build(check)
      Rake::Task["agent:clean"].invoke
    end
  end
end

namespace :env do
  desc 'Import signing RPM key'
  task :'import-rpm-key' do
    # If an RPM_SIGNING_PASSPHRASE has been passed, let's import the signing key
    sh "if [ \"$RPM_SIGNING_PASSPHRASE\" ]; then gpg --import /keys/RPM-SIGNING-KEY.private; fi"
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
    'integrations_repo' => "#{ENV['INTEGRATIONS_REPO']}"
  })

  sh "(echo '#{header}' && cat #{PROJECT_DIR}/resources/datadog-integrations/project.rb.erb) | erb > #{PROJECT_DIR}/config/projects/dd-check-#{ENV['INTEGRATION']}.rb"

  header = erb_header({
    'name' => "#{integration}",
    'PROJECT_DIR' => "#{PROJECT_DIR}",
    'integrations_repo' => "#{ENV['INTEGRATIONS_REPO']}"
  })

  sh "(echo '#{header}' && cat #{PROJECT_DIR}/resources/datadog-integrations/software.rb.erb) | erb > #{PROJECT_DIR}/config/software/dd-check-#{ENV['INTEGRATION']}-software.rb"

  build_cmd = "cd #{PROJECT_DIR} && bin/omnibus build dd-check-#{integration} --output_manifest=false"

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
    out += "<% #{key}=\"#{value}\" %>"
  end
  out
end

def linux?()
  return %w(rhel debian fedora suse gentoo slackware arch exherbo).include? @ohai['platform_family']
end

def osx?()
  return @ohai['platform_family'] == 'mac_os_x'
end

def windows?()
  return @ohai['platform_family'] == 'windows'
end
