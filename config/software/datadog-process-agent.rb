name "datadog-process-agent"
always_build true
require "./lib/ostools.rb"

process_agent_branch = ENV['PROCESS_AGENT_BRANCH']
if process_agent_branch.nil? || process_agent_branch.empty?
    process_agent_branch = "master"
end
default_version process_agent_branch

build do
  if windows?
    binary = "process-agent-windows-#{version}.exe"
    target_binary = "process-agent.exe"
    url = "https://s3.amazonaws.com/datad0g-process-agent/#{binary}"
    curl_command = "powershell -Command wget -OutFile #{binary} #{url}"
    command curl_command
    command "mv #{binary} #{Omnibus::Config.source_dir()}/datadog-agent/dd-agent/dist/#{target_binary}"
  else
    binary = "process-agent-amd64-#{version}"
    target_binary = "process-agent"
    url = "https://s3.amazonaws.com/datad0g-process-agent/#{binary}"
    curl_command = "curl -f #{url} -o #{binary}"
    command curl_command
    command "chmod +x #{binary}"
    command "mv #{binary} #{install_dir}/bin/#{target_binary}"
  end
end
