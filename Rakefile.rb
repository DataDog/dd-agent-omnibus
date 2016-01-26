PROJECT_DIR='/dd-agent-omnibus'
CORE_INTEGRATIONS_DIR='/core-integrations'
CORE_INTEGRATIONS_DIR='/playground'

namespace :agent do
  desc 'Cleanup generated files'
  task :clean do
    puts "Clean up generated files"
    sh "rm -rf /var/cache/omnibus/pkg/*"
    sh "rm -f /etc/init.d/datadog-agent"
    sh "rm -rf /etc/dd-agent"
    sh "rm -rf /opt/datadog-agent"
  end

  desc 'Pull the core-integration repo'
  task :'pull-core-integration' do
    sh "cd #{CORE_INTEGRATIONS_DIR} &&
        git fetch --all &&
        git checkout dd-check-#{ENV['INTEGRATION']}-#{ENV['VERSION']} &&
        git reset --hard"
  end

  desc 'Execute script'
  task :'execute-script' do
    sh "cd #{PROJECT_DIR} && bundle update"
    puts "building integration #{ENV['INTEGRATION']}"

    header="<% name=\"#{ENV['INTEGRATION']}\" %> \n <% version=\"#{ENV['VERSION']}\" %> \n <% build_iteration=\"#{ENV['BUILD_ITERATION']}\" %>"
    sh "(echo '#{header}' && cat #{PROJECT_DIR}/resources/datadog-integrations/project.rb.erb) | erb > #{PROJECT_DIR}/config/projects/dd-check-#{ENV['INTEGRATION']}.rb"

    header="<% name=\"#{ENV['INTEGRATION']}\" %> \n <% core_integrations=\"#{CORE_INTEGRATIONS_DIR}\" %> \n <% PROJECT_DIR=\"#{PROJECT_DIR}\" %>"
    sh "(echo '#{header}' && cat #{PROJECT_DIR}/resources/datadog-integrations/software.rb.erb) | erb > #{PROJECT_DIR}/config/software/dd-check-#{ENV['INTEGRATION']}-software.rb"

    sh "cd #{PROJECT_DIR} && bin/omnibus build dd-check-#{ENV['INTEGRATION']}"
  end

  desc 'Build an integration'
  task :'build-integration' do
    Rake::Task["agent:clean"].invoke
    Rake::Task["env:import-rpm-key"].invoke
    Rake::Task["agent:pull-core-integration"].invoke
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
