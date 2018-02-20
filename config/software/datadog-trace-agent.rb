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
ver_array = dd_agent_version.split(".")

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
  "TRACE_AGENT_VERSION" => dd_agent_version, # used by "go generate ./info" in the trace-agent
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

   # Checkout datadog-trace-agent's build dependencies
   command "#{gobin} get -d github.com/Masterminds/glide", :env => env, :cwd => agent_cache_dir

   # Pin build deps to known versions
   command "git reset --hard v0.12.3", :env => env, :cwd => glide_cache_dir
   command "#{gobin} install github.com/Masterminds/glide", :env => env, :cwd => glide_cache_dir

   # Build datadog-trace-agent
   command "#{gopath}/bin/glide install", :env => env, :cwd => agent_cache_dir       # install dependencies
   command "#{gopath}/bin/go generate ./info", :env => env, :cwd => agent_cache_dir  # generate versioning informationk
   if rhel? # temporary workaround for RHEL 5 build issue with the regular `build -a` command
     command "go install ./cmd/...", :env => env, :cwd => agent_cache_dir
     command "mv $GOPATH/bin/#{trace_agent_bin} #{install_dir}/bin/#{trace_agent_bin}", :env => env, :cwd => agent_cache_dir
   elsif windows?
     command "windmc --target pe-x86-64 -r cmd/trace-agent/windows_resources cmd/trace-agent/windows_resources/trace-agent-msg.mc", :env => env, :cwd => agent_cache_dir
     command "windres --define MAJ_VER=#{ver_array[0]} --define MIN_VER=#{ver_array[1]} --define PATCH_VER=#{ver_array[2]} -i cmd/trace-agent/windows_resources/trace-agent.rc --target=pe-x86-64 -O coff -o cmd/trace-agent/rsrc.syso", :env => env, :cwd => agent_cache_dir
     command "go build -a ./cmd/...", :env => env, :cwd => agent_cache_dir
     command "mv ./#{trace_agent_bin} #{install_dir}/bin/#{trace_agent_bin}", :env => env, :cwd => agent_cache_dir
   else
     command "go build -a ./cmd/...", :env => env, :cwd => agent_cache_dir
     command "mv ./#{trace_agent_bin} #{install_dir}/bin/#{trace_agent_bin}", :env => env, :cwd => agent_cache_dir
   end
   # clean up extra go compiler
   delete godir
end
