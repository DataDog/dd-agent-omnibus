name "datadog-process-agent"
always_build true

process_agent_branch = ENV['PROCESS_AGENT_BRANCH']
if process_agent_branch.nil? || process_agent_branch.empty?
    process_agent_branch = "master"
end
default_version process_agent_branch


build do
  # FIXME (conor): Add ship_license once repo is open source
  binary = "process-agent-amd64-#{version}"
  url = "https://s3.amazonaws.com/datad0g-process-agent/#{binary}"
  command "curl #{url} -o #{binary}"
  command "chmod +x #{binary}"
  command "mv #{binary} #{install_dir}/bin/process-agent"
end 
