name "datadog-gohai"

require "./lib/gosetup.rb"

source git: 'https://github.com/DataDog/gohai.git'

default_version "last-stable"
always_build true

go_version = "1.9.1"

build do
  ship_license "https://raw.githubusercontent.com/DataDog/gohai/#{version}/LICENSE"
  ship_license "https://raw.githubusercontent.com/DataDog/gohai/#{version}/THIRD_PARTY_LICENSES.md"

  godir = go_setup(go_version)
  gobin = "#{godir}/go/bin/go"
  gopath = "#{Omnibus::Config.cache_dir}/src/#{name}",

  env = {
    "GOPATH" => gopath,
    "GOROOT" => "#{godir}/go",
    "PATH" => "#{godir}/go/bin:#{ENV["PATH"]}",
  }

  # Put gohai into the GOPATH
  mkdir "#{gopath}/src/github.com/DataDog/"
  delete "#{gopath}/src/github.com/DataDog/gohai"
  mkdir "#{gopath}/src/github.com/DataDog/gohai"

  command "git checkout #{version} && git pull", :env => env, :cwd => "#{Omnibus::Config.source_dir}/#{name}"
  copy "#{Omnibus::Config.source_dir}/#{name}/*", "#{gopath}/src/github.com/DataDog/gohai"

  # Checkout gohai's deps
  command "#{gobin} get -u github.com/shirou/gopsutil", :env => env
  command "git checkout v2.0.0", :env => env, :cwd => "#{gopath}/src/github.com/shirou/gopsutil"
  command "#{gobin} get -u github.com/cihub/seelog", :env => env
  command "git checkout v2.6", :env => env, :cwd => "#{gopath}/src/github.com/cihub/seelog"
  # Windows depends on the registry, go get that.
  if ohai["platform"] == "windows"
    command "#{gobin} get golang.org/x/sys/windows/registry", :env => env
  end
  # Checkout and build gohai
  command "#{gobin} get -d github.com/DataDog/gohai", :env => env # No need to pull latest from remote with `-u` here since the next command checks out and pulls latest
  command "git checkout #{version} && git pull", :env => env, :cwd => "#{gopath}/src/github.com/DataDog/gohai"
  command "cd #{gopath}/src/github.com/DataDog/gohai && #{gobin} run make.go #{gobin} && mv gohai #{install_dir}/bin/gohai", :env => env

  # clean up extra go compiler
  delete godir
end
