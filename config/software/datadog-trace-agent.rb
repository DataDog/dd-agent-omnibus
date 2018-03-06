name "datadog-trace-agent"

require "./lib/ostools.rb"
require 'pathname'

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

dd_agent_version = ENV['AGENT_VERSION']


if windows?
  trace_agent_bin = "trace-agent.exe"
  gourl = "https://storage.googleapis.com/golang/go1.9.4.windows-amd64.zip"
  goout = "go.zip"
  godir = "c:/go18"
  gobin = "#{godir}/go/bin/go"
  gopath = "#{Omnibus::Config.cache_dir}/src/#{name}"

  agent_source_dir = "#{Omnibus::Config.source_dir}/datadog-trace-agent"
  glide_cache_dir = "#{gopath}/src/github.com/Masterminds/glide"
  agent_cache_dir = "#{gopath}/src/github.com/DataDog/datadog-trace-agent"

else
  trace_agent_bin = "trace-agent"
  gourl = "https://storage.googleapis.com/golang/go1.9.4.linux-amd64.tar.gz"
  goout = "go.tar.gz"
  godir = "/usr/local/go18"
  gobin = "#{godir}/go/bin/go"
  gopath = "#{Omnibus::Config.cache_dir}/src/#{name}"

  agent_source_dir = "#{Omnibus::Config.source_dir}/datadog-trace-agent"
  glide_cache_dir = "#{gopath}/src/github.com/Masterminds/glide"
  agent_cache_dir = "#{gopath}/src/github.com/DataDog/datadog-trace-agent"

end

env = {
  "GOPATH" => gopath,
  "GOROOT" => "#{godir}/go",
  "PATH" => "#{godir}/go/bin:#{ENV["PATH"]}",
  "TRACE_AGENT_VERSION" => dd_agent_version, # used by 'make' in the trace-agent
  "TRACE_AGENT_ADD_BUILD_VARS" => trace_agent_add_build_vars.to_s(),
}

build do
   ship_license "https://raw.githubusercontent.com/DataDog/datadog-trace-agent/#{version}/LICENSE"

   # download go
   command "curl #{gourl} -o #{goout}"

   delete godir
   mkdir godir

   if windows? 
    command "7z x -o#{godir} #{goout} "
   else
    command "tar zxfv #{goout} -C #{godir}"
   end
   delete goout

   # Put datadog-trace-agent into a valid GOPATH
   mkdir "#{gopath}/src/github.com/DataDog/"
   delete "#{gopath}/src/github.com/DataDog/datadog-trace-agent"
   mkdir "#{gopath}/src/github.com/DataDog/datadog-trace-agent"
   move "#{agent_source_dir}/*", "#{gopath}/src/github.com/DataDog/datadog-trace-agent"

   if windows?
     # build windows resources
     command "make windows", :env => env, :cwd => agent_cache_dir
   end

   # build datadog-trace-agent
   command "make install", :env => env, :cwd => agent_cache_dir

   if rhel? # temporary workaround for RHEL 5 build issue with the regular `build -a` command
     command "mv $GOPATH/bin/#{trace_agent_bin} #{install_dir}/bin/#{trace_agent_bin}", :env => env, :cwd => agent_cache_dir
   else
     command "mv #{gopath}/bin/#{trace_agent_bin} #{install_dir}/bin/#{trace_agent_bin}", :env => env, :cwd => agent_cache_dir
   end
   # clean up extra go compiler
   delete godir
end
