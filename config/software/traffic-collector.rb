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

# Self-explanatory: this specifies the name of the software
# You will need to add this as a dependency in config/projects/netsil-collectors.rb. Look at the end of that file to see how we do it for traffic-collector
name "traffic-collector"

# This source path is copied/volume-mounted at dev-time from the AOC repo.
# E.g. in the omnibus dockerfiles, we COPY tools/collectors/rpcapd to /root/collectors/rpcapd
source path: "/root/collectors/rpcapd"

# These dependencies come from the repo github.com/luhkevin/omnibus-software
# Check the files in config/software in that repo to see how these dependencies are written.
# If you need to add custom dependencies (e.g. let's say you need a library called `libfoo`),
# you will have to add a software definition at `config/software/libfoo` in the omnibus-software repo above.
dependency "libpcap"
dependency "libsodium"

# Compile-time environment variables
env = {
  "LIBRARY_PATH" => "#{install_dir}/embedded/lib",
  "CPATH" => "#{install_dir}/embedded/include",
  "LD_LIBRARY_PATH" => "#{install_dir}/embedded/lib"
}

build do
  # The #{install_dir} variable is /opt/netsil/collectors.
  # Basically this command is making the actual user-space directory for the traffic-collector that omnibus will then package into the DEB or RPM
  mkdir "#{install_dir}/traffic-collector"

  # Notice that we don't specify which directory this is running from.
  # By default, all these commands -- e.g. `make` or the `copy` step -- are happening from the "source path:" directory defined above.
  command "make PLATFORM=linux", :env => env

  # To reiterate the point about #{install_dir}, here we are copying rpcapd into the install_dir, so omnibus can package it when it generates the DEB or RPM
  copy "winpcap/wpcap/libpcap/rpcapd/rpcapd", "#{install_dir}/traffic-collector/rpcapd"
  copy "supervisord-rpcapd.sh", "#{install_dir}/traffic-collector/supervisord-rpcapd.sh"
end
