#
# Copyright Netsil (c) 2016
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

name "traffic-collector"

# A software can specify more than one version that is available for install
# version("#{version}") { source url: "https://github.com/DataDog/dd-agent/archive/#{version}.tar.gz" }
#source url: "https://s3.amazonaws.com/bin.netsil.io/rpcapd/traffic-collector.tar.gz",
#       md5: "437e0f251868d07ebb020be1a13be32f"

source path: "/root/collectors/rpcapd"

# This is the path, inside the tarball, where the source resides
#relative_path "traffic-collector"

dependency "libpcap"
dependency "libsodium"

env = {
  "LIBRARY_PATH" => "#{install_dir}/embedded/lib",
  "CPATH" => "#{install_dir}/embedded/include",
  "LD_LIBRARY_PATH" => "#{install_dir}/embedded/lib"
}

build do
  # Setup a default environment from Omnibus - you should use this Omnibus
  # helper everywhere. It will become the default in the future.
  #env = with_standard_compiler_flags(with_embedded_path)
  mkdir "#{install_dir}/traffic-collector"
  command "make PLATFORM=linux", :env => env
  copy "winpcap/wpcap/libpcap/rpcapd/rpcapd", "#{install_dir}/traffic-collector/rpcapd"
end
