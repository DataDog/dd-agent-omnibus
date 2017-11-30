name "datadog-metro"

require "./lib/gosetup.rb"

dependency "libpcap"

source git: 'https://github.com/DataDog/go-metro.git'

default_version "last-stable"
always_build true

go_version = "1.9.1"

build do
  ship_license "https://raw.githubusercontent.com/DataDog/go-metro/master/LICENSE"
  ship_license "https://raw.githubusercontent.com/DataDog/go-metro/master/THIRD_PARTY_LICENSES.md"

  block do
    srcdir = "#{Omnibus::Config.source_dir}/#{name}"
    gopath = "#{Omnibus::Config.cache_dir}/go/src/#{name}",
    godir = go_setup(go_version)
    gobin = "#{godir}/go/bin/go"

    env = {
      "GOPATH" => gopath,
      "GOROOT" => "#{godir}/go",
      "PATH" => "#{godir}/go/bin:#{ENV["PATH"]}",
    }

    # Put go-metro into the GOPATH
    mkdir "#{gopath}/src/github.com/DataDog/"
    delete "#{gopath}/src/github.com/DataDog/go-metro"
    mkdir "#{gopath}/src/github.com/DataDog/go-metro"

    command "git checkout #{version} && git pull", :env => env, :cwd => srcdir
    copy "#{srcdir}/*", "#{gopath}/src/github.com/DataDog/go-metro"

    command "mkdir -p #{gopath}/src/github.com/DataDog", :env => env
    command "#{gobin} get -v -d github.com/DataDog/go-metro", :env => env, :cwd => "#{gopath}"
    command "git checkout #{version} && git pull", :env => env, :cwd => "#{gopath}/src/github.com/DataDog/go-metro"
    command "#{gobin} get -v -d github.com/cihub/seelog", :env => env, :cwd => "#{gopath}"
    command "#{gobin} get -v -d github.com/google/gopacket", :env => env, :cwd => "#{gopath}"
    command "#{gobin} get -v -d github.com/DataDog/datadog-go/statsd", :env => env, :cwd => "#{gopath}"
    command "#{gobin} get -v -d gopkg.in/tomb.v2", :env => env, :cwd => "#{gopath}"
    command "#{gobin} get -v -d gopkg.in/yaml.v2", :env => env, :cwd => "#{gopath}"
    patch :source => "libpcap-static-link.patch", :plevel => 1,
          :acceptable_output => "Reversed (or previously applied) patch detected",
          :target => "/var/cache/omnibus/src/datadog-metro/src/github.com/google/gopacket/pcap/pcap.go"
    command "#{gobin} build -o #{install_dir}/bin/go-metro github.com/DataDog/go-metro", :env => env, :cwd => "#{gopath}"

    # clean up extra go compiler
    delete godir
  end
end
