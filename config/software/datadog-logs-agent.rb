name "datadog-logs-agent"
always_build true

include_logs_agent = ENV['INCLUDE_LOGS_AGENT']
if include_logs_agent.nil? || include_logs_agent.empty?
    include_logs_agent = false
end

logs_agent_version = ENV['LOGS_AGENT_VERSION']
if logs_agent_version.nil? || logs_agent_version.empty?
    logs_agent_version = "alpha"
end

build do
  binary = "logagent"

  if include_logs_agent
      if linux?
        url = "https://s3.amazonaws.com/public.binaries.sheepdog.datad0g.com/agent/#{logs_agent_version}/linux-amd64/#{binary}"
        command "curl #{url} -o #{binary}"
        command "chmod +x #{binary}"
        command "mv #{binary} #{install_dir}/bin/logs-agent"
      end
  end
end 
