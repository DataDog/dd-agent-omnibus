name "datadog-trace-agent"
source git: 'https://github.com/DataDog/datadog-trace-agent.git'

trace_agent_branch = ENV['TRACE_AGENT_BRANCH']

if trace_agent_branch.nil? || trace_agent_branch.empty?
      default_version 'last-stable'
else
      default_version trace_agent_branch
end

dd_agent_version = ENV['AGENT_VERSION']

gourl = "https://storage.googleapis.com/golang/go1.7.1.linux-amd64.tar.gz"
goout = "go.tar.gz"
godir = "/usr/local/go17"
gobin = "#{godir}/go/bin/go"

agent_source_dir = "#{Omnibus::Config.source_dir}/datadog-trace-agent"

env = {
  "GOPATH" => "#{Omnibus::Config.cache_dir}/src/#{name}",
  "GOROOT" => "/usr/local/go17/go",
  "PATH" => "#{godir}/go/bin:#{ENV["PATH"]}"
}

build do
   ship_license "https://raw.githubusercontent.com/DataDog/datadog-trace-agent/#{version}/LICENSE"
   # download go1.7
   command "curl #{gourl} -o #{goout}"
   command "mkdir -p #{godir}"
   command "tar zxfv #{goout} -C #{godir}"

   # Put datadog-trace-agent into a valid GOPATH
   command "mkdir -p $GOPATH/src/github.com/DataDog/", :env => env
   command "rm -rf $GOPATH/src/github.com/DataDog/datadog-trace-agent && mv #{agent_source_dir} $GOPATH/src/github.com/DataDog/", :env => env

   # Checkout datadog-trace-agent's build dependencies
   command "#{gobin} get -d github.com/robfig/glock", :env => env, :cwd => "#{Omnibus::Config.cache_dir}/src/datadog-trace-agent/src/github.com"

   # Pin build deps to known versions
   command "git checkout 7bc8ce51048e2adc11733f90a87b1c02fb7feebe", :env => env, :cwd => "#{Omnibus::Config.cache_dir}/src/datadog-trace-agent/src/github.com/robfig/glock"
   command "#{gobin} install github.com/robfig/glock", :env => env, :cwd => "#{Omnibus::Config.cache_dir}/src/datadog-trace-agent/src/github.com/robfig/glock"

   # Build datadog-trace-agent
   command "$GOPATH/bin/glock sync github.com/DataDog/datadog-trace-agent", :env => env, :cwd => "#{Omnibus::Config.cache_dir}/src/datadog-trace-agent/src/github.com/DataDog/datadog-trace-agent"
   command "#{gobin} build -i -o trace-agent -X main.Version=#{dd_agent_version} github.com/DataDog/datadog-trace-agent/agent && mv ./trace-agent #{install_dir}/bin/trace-agent", :env => env, :cwd => "#{Omnibus::Config.cache_dir}/src/datadog-trace-agent/src/github.com/DataDog/datadog-trace-agent"
end
