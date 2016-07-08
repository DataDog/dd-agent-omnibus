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

name "sslsplit"

source path: "/root/collectors/sslsplit"

dependency "pkg-config"
dependency "libevent"
dependency "openssl"
dependency "libsodium"
dependency "libpcap"

env = {
  "LIBRARY_PATH" => "#{install_dir}/embedded/lib",
  "CPATH" => "#{install_dir}/embedded/include",
  "LD_LIBRARY_PATH" => "#{install_dir}/embedded/lib",
  "LIBEVENT_BASE" => "#{install_dir}/embedded",
  "PKGCONFIG" => "#{install_dir}/embedded/bin/pkg-config"
}

build do
  mkdir "#{install_dir}/traffic-collector"
  command "make", :env => env
  copy "sslsplit", "#{install_dir}/traffic-collector/sslsplit"
  copy "supervisord-sslsplit.sh", "#{install_dir}/traffic-collector/supervisord-sslsplit.sh"
  command "openssl genrsa -out #{install_dir}/traffic-collector/netsil-ca.key 512"
  command "./genrsa.sh"
  command "chmod 600 #{install_dir}/traffic-collector/netsil-ca.crt"
  command "chmod 600 #{install_dir}/traffic-collector/netsil-ca.key"
end
