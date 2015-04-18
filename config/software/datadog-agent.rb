name "datadog-agent"

local_agent_repo = ENV['LOCAL_AGENT_REPO']
if local_agent_repo.nil? || local_agent_repo.empty?
  source git: "https://github.com/DataDog/dd-agent.git"
else
  # For local development
  source path: ENV['LOCAL_AGENT_REPO']
end

agent_branch = ENV['AGENT_BRANCH']
if agent_branch.nil? || agent_branch.empty?
  default_version 'master'
else
  default_version agent_branch
end

relative_path "dd-agent"
always_build true

build do
   license "https://raw.githubusercontent.com/DataDog/dd-agent/master/LICENSE"
   # Agent code
   command "mkdir -p #{install_dir}/agent/"
   command "cp -R checks.d #{install_dir}/agent/"
   command "cp -R checks #{install_dir}/agent/"
   command "cp -R dogstream #{install_dir}/agent/"
   command "cp -R resources #{install_dir}/agent/"
   command "cp -R utils #{install_dir}/agent/"
   command "cp *.py #{install_dir}/agent/"
   command "cp datadog-cert.pem #{install_dir}/agent/"

   # Configuration files
   command "mkdir -p /etc/dd-agent"
   if Ohai['platform_family'] == 'rhel'
     command "cp packaging/centos/datadog-agent.init /etc/init.d/datadog-agent"
   elsif Ohai['platform_family'] == 'debian'
     command "cp packaging/debian/datadog-agent.init /etc/init.d/datadog-agent"
   end
   
   command "cp packaging/supervisor.conf /etc/dd-agent/supervisor.conf"
   command "cp datadog.conf.example /etc/dd-agent/datadog.conf.example"
   command "cp -R conf.d /etc/dd-agent/"
   command "mkdir -p /etc/dd-agent/checks.d/"

   # Create symlinks
   command "ln -sf /opt/datadog-agent/agent/agent.py /usr/bin/dd-agent"
   command "ln -sf /opt/datadog-agent/agent/dogstatsd.py /usr/bin/dogstatsd"
   command "ln -sf /opt/datadog-agent/agent/ddagent.py /usr/bin/dd-forwarder"
   command "chmod 755 /usr/bin/dd-agent"
   command "chmod 755 /usr/bin/dogstatsd"
   command "chmod 755 /usr/bin/dd-forwarder"
end
