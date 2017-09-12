name "datadog-logs-agent"
always_build true

build do
  binary = "logagent"
  logs_agent_version = "alpha"

  if linux?
    url = "https://s3.amazonaws.com/public.binaries.sheepdog.datad0g.com/agent/#{logs_agent_version}/linux-amd64/#{binary}"
    command "curl #{url} -o #{binary}"
    command "chmod +x #{binary}"
    command "mv #{binary} #{install_dir}/bin/logs-agent"
  end
end 
