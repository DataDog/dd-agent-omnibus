name "datadog-dogstatsd6"
source git: 'https://github.com/DataDog/datadog-agent.git'

trace_agent_branch = ENV['AGENT6_BRANCH']
if trace_agent_branch.nil? || trace_agent_branch.empty?
  trace_agent_branch = 'master'
end
default_version trace_agent_branch

# would rather use gimme and an env var
gourl = "https://storage.googleapis.com/golang/go1.8.linux-amd64.tar.gz"
goout = "go.tar.gz"
godir = "/usr/local/go18"
gobin = "#{godir}/go/bin/go"
gopath = "#{Omnibus::Config.cache_dir}/src/#{name}"

agent_source_dir = "#{Omnibus::Config.source_dir}/datadog-agent"
glide_cache_dir = "#{gopath}/src/github.com/Masterminds/glide"
agent_cache_dir = "#{gopath}/src/github.com/DataDog/datadog-agent"

env = {
  "GOPATH" => gopath,
  "GOROOT" => "/usr/local/go18/go",
  "PATH" => "#{godir}/go/bin:#{ENV["PATH"]}",
  "AGENT6_VERSION" => dd_agent_version, # used by gorake.rb in the agent6
}

build do
   ship_license "https://raw.githubusercontent.com/DataDog/datadog-agent/#{version}/LICENSE"

   # download go
   command "curl #{gourl} -o #{goout}"
   mkdir godir
   command "tar zxfv #{goout} -C #{godir}"

   # Put datadog-agent into a valid GOPATH
   mkdir "#{gopath}/src/github.com/DataDog/"
   delete "#{gopath}/src/github.com/DataDog/datadog-agent"
   move agent_source_dir, "#{gopath}/src/github.com/DataDog/"

   # Checkout datadog-agent's build dependencies
   command "#{gobin} get -d github.com/Masterminds/glide", :env => env, :cwd => agent_cache_dir
   command "#{gobin} install github.com/Masterminds/glide", :env => env, :cwd => glide_cache_dir

   # Build datadog-agent
   command "$GOPATH/bin/glide install", :env => env, :cwd => agent_cache_dir
   command "rake deps", :env => env, :cwd => agent_cache_dir
   command "rake dogstatsd:build", :env => env, :cwd => agent_cache_dir
   command "mv ./bin/dogstatsd/dogstatsd.bin #{install_dir}/bin/dogstatsd6.bin", :env => env, :cwd => agent_cache_dir
end
