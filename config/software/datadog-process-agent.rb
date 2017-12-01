name "datadog-process-agent"

require "./lib/ostools.rb"
require "./lib/gosetup.rb"

always_build true

from_source = ENV['PROCESS_AGENT_SOURCE_BUILD'] || false

process_agent_branch = ENV['PROCESS_AGENT_BRANCH']
if process_agent_branch.nil? || process_agent_branch.empty?
    process_agent_branch = "master"
end
default_version process_agent_branch

go_version = "1.9.1"

if windows?
  process_agent_bin = "process-agent.exe"
else
  process_agent_bin = "process-agent"
end

gopath = "#{Omnibus::Config.cache_dir}/go/src/#{name}"
agent_source_dir = "#{Omnibus::Config.source_dir}/datadog-process-agent"
glide_cache_dir = "#{gopath}/src/github.com/Masterminds/glide"
agent_cache_dir = "#{gopath}/src/github.com/DataDog/datadog-process-agent"

build do
  if from_source
    block do
      # download go
      godir, gobin = go_setup(go_version)

      env = {
        "GOPATH" => gopath,
        "GOROOT" => "#{godir}/go",
        "PATH" => "#{godir}/go/bin:#{ENV["PATH"]}",
      }

      # Put go-metro into the GOPATH
      mkdir "#{gopath}/src/github.com/DataDog/"
      delete "#{gopath}/src/github.com/DataDog/datadog-process-agent"
      mkdir "#{gopath}/src/github.com/DataDog/datadog-process-agent"
      move "#{agent_source_dir}/*", "#{gopath}/src/github.com/DataDog/datadog-process-agent"

      # Checkout datadog-process-agent's build dependencies
      command "#{gobin} get -d github.com/Masterminds/glide", :env => env, :cwd => agent_cache_dir

      # Pin build deps to known versions
      command "git reset --hard v0.12.3", :env => env, :cwd => glide_cache_dir
      command "#{gobin} install github.com/Masterminds/glide", :env => env, :cwd => glide_cache_dir

      command "rake build", :env => env, :cwd => agent_cache_dir
      command "mv ./#{process_agent_bin} #{install_dir}/bin/#{process_agent_bin}", :env => env, :cwd => agent_cache_dir
    end
  else
    # FIXME (conor): Add ship_license once repo is open source
    binary = "process-agent-amd64-#{version}"
    url = "https://s3.amazonaws.com/datad0g-process-agent/#{binary}"
    # -f will make the failure noisy
    command "curl -f #{url} -o #{binary}"
    command "chmod +x #{binary}"
    command "mv #{binary} #{install_dir}/bin/process-agent"
  end
end
