name "datadog-metro"

require "./lib/gosetup.rb"

dependency "libpcap"

default_version "last-stable"
always_build true

go_version = "1.9.1"

build do
  ship_license "https://raw.githubusercontent.com/DataDog/go-metro/master/LICENSE"
  ship_license "https://raw.githubusercontent.com/DataDog/go-metro/master/THIRD_PARTY_LICENSES.md"

  godir = go_setup(go_version)
  gobin = "#{godir}/go/bin/go"
  gopath = "#{Omnibus::Config.cache_dir}/src/#{name}",

  env = {
    "GOPATH" => gopath,
    "GOROOT" => "#{godir}/go",
    "PATH" => "#{godir}/go/bin:#{ENV["PATH"]}",
  }

  command "mkdir -p #{gopath}/src/github.com/DataDog", :env => env
  command "#{gobin} get -v -d github.com/DataDog/go-metro", :env => env, :cwd => "#{gopath}"
  command "git checkout #{default_version} && git pull", :env => env, :cwd => "#{gopath}/src/github.com/DataDog/go-metro"
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
