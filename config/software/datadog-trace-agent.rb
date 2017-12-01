name "datadog-trace-agent"

require 'pathname'

require "./lib/ostools.rb"
require "./lib/gosetup.rb"

source git: 'https://github.com/DataDog/datadog-trace-agent.git'

trace_agent_branch = ENV['TRACE_AGENT_BRANCH']
if trace_agent_branch.nil? || trace_agent_branch.empty?
  trace_agent_branch = 'master'
end
default_version trace_agent_branch

trace_agent_add_build_vars = true
if ENV.has_key?('TRACE_AGENT_ADD_BUILD_VARS') && ENV['TRACE_AGENT_ADD_BUILD_VARS'] == 'false'
  trace_agent_add_build_vars = false
end

go_version = "1.9.1"
dd_agent_version = ENV['AGENT_VERSION']


if windows?
  trace_agent_bin = "trace-agent.exe"
else
  trace_agent_bin = "trace-agent"
end

gopath = "#{Omnibus::Config.cache_dir}/go"
agent_source_dir = "#{Omnibus::Config.source_dir}/datadog-trace-agent"
glide_cache_dir = "#{gopath}/src/github.com/Masterminds/glide"
agent_cache_dir = "#{gopath}/src/github.com/DataDog/datadog-trace-agent"

build do
  ship_license "https://raw.githubusercontent.com/DataDog/datadog-trace-agent/#{version}/LICENSE"

  # download go
  godir, gobin = go_setup(go_version)
  
  env = {
    "GOPATH" => gopath,
    "GOROOT" => "#{godir}/go",
    "PATH" => "#{godir}/go/bin:#{ENV["PATH"]}",
    "TRACE_AGENT_VERSION" => dd_agent_version, # used by gorake.rb in the trace-agent
    "TRACE_AGENT_ADD_BUILD_VARS" => trace_agent_add_build_vars.to_s(),
  }

  # Put datadog-trace-agent into a valid GOPATH
  mkdir "#{gopath}/src/github.com/DataDog/"
  delete "#{gopath}/src/github.com/DataDog/datadog-trace-agent"
  mkdir "#{gopath}/src/github.com/DataDog/datadog-trace-agent"
  move "#{agent_source_dir}/*", "#{gopath}/src/github.com/DataDog/datadog-trace-agent"

  # Checkout datadog-trace-agent's build dependencies
  command "#{gobin} get -d github.com/Masterminds/glide", :env => env, :cwd => agent_cache_dir

  # Pin build deps to known versions
  command "git reset --hard v0.12.3", :env => env, :cwd => glide_cache_dir
  command "#{gobin} install github.com/Masterminds/glide", :env => env, :cwd => glide_cache_dir

  # Build datadog-trace-agent
  command "#{gopath}/bin/glide install", :env => env, :cwd => agent_cache_dir
  if rhel? # temporary workaround for RHEL 5 build issue with the regular `build -a` command
    command "rake install", :env => env, :cwd => agent_cache_dir
    command "mv $GOPATH/bin/#{trace_agent_bin} #{install_dir}/bin/#{trace_agent_bin}", :env => env, :cwd => agent_cache_dir
  elsif windows?
   command "rake build windres=true", :env => env, :cwd => agent_cache_dir
   command "mv ./#{trace_agent_bin} #{install_dir}/bin/#{trace_agent_bin}", :env => env, :cwd => agent_cache_dir
  else
    command "rake build", :env => env, :cwd => agent_cache_dir
    command "mv ./#{trace_agent_bin} #{install_dir}/bin/#{trace_agent_bin}", :env => env, :cwd => agent_cache_dir
  end
  # clean up extra go compiler
  delete godir
end
