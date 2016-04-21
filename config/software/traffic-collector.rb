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
source url: "https://s3.amazonaws.com/bin.netsil.io/rpcapd/traffic-collector.tar.gz",
       md5: "6f995d41797206265b443828fcb055ae"

# This is the path, inside the tarball, where the source resides
relative_path "traffic-collector"

puts "#{project_dir}"

endpoint_env = 'NETSIL_SP_ENDPOINT'
default_endpoint = 'localhost, 2003'

build do
  # Setup a default environment from Omnibus - you should use this Omnibus
  # helper everywhere. It will become the default in the future.
  env = with_standard_compiler_flags(with_embedded_path)

  # make sure env has a default netsil dd endpoint
  if not env.key?(endpoint_env)
    env[endpoint_env] = default_endpoint
  end

  if linux?
    mkdir "#{install_dir}/traffic-collector/"
    copy 'rpcapd', "#{install_dir}/traffic-collector/"
    # rpcapd.ini will be re-generated when fetching the package
    copy 'rpcapd.ini', "#{install_dir}/traffic-collector/"

    # Install supervisor conf files
    mkdir "#{install_dir}/conf.d"
    copy 'netsil-traffic-collector.conf', "#{install_dir}/conf.d/"
  end
end
