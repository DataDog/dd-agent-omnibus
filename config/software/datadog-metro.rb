name "datadog-metro"
default_version "1.0.0"

always_build true

env = {
  "GOROOT" => "/usr/local/go",
  "GOPATH" => "#{Omnibus::Config.cache_dir}/src/#{name}",
}

dependency "libpcap"

if ohai["platform_family"] == "rhel"
  source :url => "https://s3.amazonaws.com/dd-agent/go-metro/gometro-centos6-#{version}"

  version "1.0.0" do
    source :sha256 => "a6fb05dcbe0f412eaac44095db67a8d71cce6c66dc900b0b78258de4ee43bf2f"
  end
end

#TODO: complete OSX support.
if ohai["platform_family"] == "mac_os_x"
  env.delete "GOROOT"
  gobin = "/usr/local/bin/go"
else
  gobin = "/usr/local/go/bin/go"
end

build do
  ship_license "https://raw.githubusercontent.com/DataDog/go-metro/master/LICENSE"
  ship_license "https://raw.githubusercontent.com/DataDog/go-metro/master/THIRD_PARTY_LICENSES.md"

  if ohai["platform_family"] == "rhel"
    command "mv gometro-centos6-#{version} #{install_dir}/bin/go-metro.bin"
    command "chmod ug+x #{install_dir}/bin/go-metro.bin"
  else
    command "#{gobin} get -v -d github.com/DataDog/go-metro", :env => env
    command "git fetch && git checkout #{version}", :env => env, :cwd => "#{Omnibus::Config.cache_dir}/src/#{name}/src/github.com/DataDog/go-metro"
    command "#{gobin} get -v -d github.com/cihub/seelog", :env => env, :cwd => "#{Omnibus::Config.cache_dir}/src/#{name}"
    command "#{gobin} get -v -d github.com/google/gopacket", :env => env, :cwd => "#{Omnibus::Config.cache_dir}/src/#{name}"
    command "#{gobin} get -v -d github.com/DataDog/datadog-go/statsd", :cwd => "#{Omnibus::Config.cache_dir}/src/#{name}"
    command "#{gobin} get -v -d gopkg.in/tomb.v2", :env => env, :cwd => "#{Omnibus::Config.cache_dir}/src/#{name}"
    command "#{gobin} get -v -d gopkg.in/yaml.v2", :env => env, :cwd => "#{Omnibus::Config.cache_dir}/src/#{name}"
    patch :source => "libpcap-static-link.patch", :plevel => 1,
          :acceptable_output => "Reversed (or previously applied) patch detected",
          :target => "#{Omnibus::Config.cache_dir}/src/#{name}/src/github.com/google/gopacket/pcap/pcap_unix.go"
    command "#{gobin} build -o #{install_dir}/bin/go-metro.bin github.com/DataDog/go-metro", :env => env, :cwd => "#{Omnibus::Config.cache_dir}/src/#{name}"
  end
end
