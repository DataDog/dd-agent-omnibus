PROJECT_DIR='/dd-agent-omnibus'

namespace :agent do
  desc 'Cleanup generated files'
  task :clean do
    puts "Clean up generated files"
    sh "rm -rf /var/cache/omnibus/pkg/*"
    sh "rm -f /etc/init.d/datadog-agent"
    sh "rm -rf /etc/dd-agent"
    sh "rm -rf /opt/datadog-agent"
  end

  desc 'Pull the integrations repo'
  task :'pull-integrations' do
    sh "cd /#{ENV['INTEGRATIONS_REPO']} &&
        git fetch --all &&
        git checkout dd-check-#{ENV['INTEGRATION']}-#{ENV['VERSION']} &&
        git reset --hard"
  end

  desc 'Execute script'
  task :'execute-script' do
    sh "cd #{PROJECT_DIR} && bundle update"
    puts "building integration #{ENV['INTEGRATION']}"

    header = erb_header({
      'name' => "#{ENV['INTEGRATION']}",
      'version' => "#{ENV['VERSION']}",
      'build_iteration' => "#{ENV['BUILD_ITERATION']}"
    })
    sh "(echo '#{header}' && cat #{PROJECT_DIR}/resources/datadog-integrations/project.rb.erb) | erb > #{PROJECT_DIR}/config/projects/dd-check-#{ENV['INTEGRATION']}.rb"

    header = erb_header({
      'name' => "#{ENV['INTEGRATION']}",
      'PROJECT_DIR' => "#{PROJECT_DIR}",
      'integrations_repo' => "#{ENV['INTEGRATIONS_REPO']}"
    })
    sh "(echo '#{header}' && cat #{PROJECT_DIR}/resources/datadog-integrations/software.rb.erb) | erb > #{PROJECT_DIR}/config/software/dd-check-#{ENV['INTEGRATION']}-software.rb"

    sh "cd #{PROJECT_DIR} && bin/omnibus build dd-check-#{ENV['INTEGRATION']} --output_manifest=false"
  end

  desc 'Build an integration'
  task :'build-integration' do
    Rake::Task["agent:clean"].invoke
    Rake::Task["env:import-rpm-key"].invoke
    Rake::Task["agent:pull-integrations"].invoke
    Rake::Task["agent:execute-script"].invoke
  end

end

namespace :env do
  desc 'Import signing RPM key'
  task :'import-rpm-key' do
    # If an RPM_SIGNING_PASSPHRASE has been passed, let's import the signing key
    sh "if [ \"$RPM_SIGNING_PASSPHRASE\" ]; then gpg --import /keys/RPM-SIGNING-KEY.private; fi"
  end
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
