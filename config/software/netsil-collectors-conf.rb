#
# Copyright Netsil
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

# These options are required for all software definitions
name "netsil-collectors-conf"

# Sources may be URLs, git locations, or path locations
#source url: "https://s3.amazonaws.com/bin.netsil.io/netsil-collectors/netsil-collectors-meta.tar.gz",
#source url: "https://s3.amazonaws.com/bin.netsil.io/netsil-collectors/netsil-collectors.tar.gz",
#       md5: "8c2b2ac008c4d518cdb8ccd100f88ee9"

source path: "/root/collectors"
#source path: "/root/omnibus/staging/netsil-collectors-conf.tar.gz"
# A software can specify more than one version that is available for install
# version("1.2.6") { source md5: "618e944d7c7cd6521551e30b32322f4a" }
# default_version "1.2.6"

build do
  # Setup a default environment from Omnibus - you should use this Omnibus
  # helper everywhere. It will become the default in the future.
  env = with_standard_compiler_flags(with_embedded_path)

  # Setup supervisor config
  if linux?
    mkdir "#{install_dir}/conf.d"

    copy 'init/supervisor/netsil-collectors.conf', "#{install_dir}/conf.d/"
    copy 'init/netsil-collectors-logrotate', "#{install_dir}/conf.d/"
    copy 'scripts/start.sh', "#{install_dir}/start.sh"
    command "chmod 755 #{install_dir}/start.sh"

    # Init scripts
    if ohai['platform_family'] == 'rhel'
        copy 'init/rhel/netsil-collectors.init', '/etc/rc.d/init.d/netsil-collectors'
        copy 'init/rhel/netsil-collectors-stub.init', "#{install_dir}/conf.d/netsil-collectors-stub"
        command "chmod 755 #{install_dir}/conf.d/netsil-collectors-stub"
        command 'chmod 755 /etc/rc.d/init.d/netsil-collectors'
    elsif ohai['platform_family'] == 'debian'
        copy 'init/debian/netsil-collectors.init', '/etc/init.d/netsil-collectors'
        command 'chmod 755 /etc/init.d/netsil-collectors'
        copy 'init/debian/netsil-collectors-stub.init', "#{install_dir}/conf.d/netsil-collectors-stub"
        command "chmod 755 #{install_dir}/conf.d/netsil-collectors-stub"
        mkdir '/lib/systemd/system'
        copy 'init/debian/netsil-collectors.service', '/lib/systemd/system/netsil-collectors.service'
    end
  end
end
