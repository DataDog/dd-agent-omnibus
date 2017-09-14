name "datadog-logs-agent"
always_build true

puts "debug tristan"
puts ENV['INCLUDE_LOGS_AGENT']
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

  puts include_logs_agent
  if include_logs_agent
    puts "including the logs-agent"
    if linux?
      url = "https://s3.amazonaws.com/public.binaries.sheepdog.datad0g.com/agent/#{logs_agent_version}/linux-amd64/#{binary}"
      command "curl #{url} -o #{binary}"
      command "chmod +x #{binary}"
      command "mv #{binary} #{install_dir}/bin/logs-agent"
    end
  else
    puts "not including the logs-agent"
  end
end 
