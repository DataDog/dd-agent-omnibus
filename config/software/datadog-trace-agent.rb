name "datadog-trace-agent"

require "./lib/ostools.rb"
require 'pathname'

source git: 'https://github.com/DataDog/datadog-agent.git'

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


build do
   ship_license "https://raw.githubusercontent.com/DataDog/datadog-agent/LICENSE"

    agent_source_dir = windows_safe_path("#{Omnibus::Config.source_dir}/datadog-trace-agent")
    if windows?
      trace_agent_bin = "trace-agent.exe"
      gourl = "https://storage.googleapis.com/golang/go1.10.3.windows-amd64.zip"
      goout = "go.zip"
      godir = windows_safe_path("c:/go110")
      gobin = windows_safe_path("#{godir}/go/bin/go")
      gopath = windows_safe_path("c:/gotmp")

      agent_cache_dir = windows_safe_path("#{gopath}/src/github.com/DataDog/datadog-agent")

      env = {
        "GOPATH" => gopath,
        "GOROOT" => windows_safe_path("#{godir}/go"),
        "PATH" => "#{gopath}\\bin;#{godir}\\go\\bin;#{ENV["PATH"]}",
        "TRACE_AGENT_VERSION" => dd_agent_version, # used by 'make' in the trace-agent
        "TRACE_AGENT_ADD_BUILD_VARS" => trace_agent_add_build_vars.to_s(),
      }

    else
      trace_agent_bin = "trace-agent"
      gourl = "https://storage.googleapis.com/golang/go1.10.3.linux-amd64.tar.gz"
      goout = "go.tar.gz"
      godir = "/usr/local/go110"
      gobin = "#{godir}/go/bin/go"
      gopath = "#{Omnibus::Config.cache_dir}/src/#{name}"

      agent_cache_dir = "#{gopath}/src/github.com/DataDog/datadog-agent"

      env = {
        "GOPATH" => gopath,
        "GOROOT" => "#{godir}/go",
        "PATH" => "#{gopath}/bin:#{godir}/go/bin:#{ENV["PATH"]}",
        "TRACE_AGENT_VERSION" => dd_agent_version, # used by 'make' in the trace-agent
        "TRACE_AGENT_ADD_BUILD_VARS" => trace_agent_add_build_vars.to_s(),
      }
    end

   # download go
   command "curl #{gourl} -o #{goout}"

   delete godir
   mkdir godir

   if windows?
    command "7z x -aoa -o#{godir} #{goout} "
   else
    command "tar zxfv #{goout} -C #{godir}"
   end
   delete goout

   # Put datadog-agent into a valid GOPATH
   mkdir agent_cache_dir  # will also create parent dirs
   delete agent_cache_dir, :force => true
   move agent_source_dir, agent_cache_dir, :force => true, :verbose => true

   if windows?
    mkdir windows_safe_path("#{gopath}/bin")
    dep = windows_safe_path("#{gopath}/bin/dep.exe")
    command "curl -sSL https://github.com/golang/dep/releases/download/v0.5.0/dep-windows-amd64.exe -o #{dep}"
    command "#{dep} ensure", :env => env, :cwd => agent_cache_dir
   else
    command "go get -u github.com/golang/dep/cmd/dep", :env => env, :cwd => agent_cache_dir
    command "dep ensure", :env => env, :cwd => agent_cache_dir
   end

   if windows?
     # build windows resources
     command "make -f Makefile.trace windows", :env => env, :cwd => agent_cache_dir
   end

   # build datadog-trace-agent
   command "make -f Makefile.trace install", :env => env, :cwd => agent_cache_dir

   if rhel? # temporary workaround for RHEL 5 build issue with the regular `build -a` command
     command "mv $GOPATH/bin/#{trace_agent_bin} #{install_dir}/bin/#{trace_agent_bin}", :env => env, :cwd => agent_cache_dir
   elsif windows?
     command "mv #{gopath}/bin/#{trace_agent_bin} #{Omnibus::Config.source_dir()}/datadog-agent/dd-agent/dist/#{trace_agent_bin}", :env => env, :cwd => agent_cache_dir
   else
     command "mv #{gopath}/bin/#{trace_agent_bin} #{install_dir}/bin/#{trace_agent_bin}", :env => env, :cwd => agent_cache_dir
   end
   # clean up extra go compiler
   delete godir
end
