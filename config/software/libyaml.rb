#
# Copyright:: Copyright (c) 2012-2014 Chef Software, Inc.
# License:: Apache License, Version 2.0
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

name "libyaml"
default_version "0.1.7"

source :url => "https://github.com/yaml/libyaml/archive/#{version}.tar.gz",
       :sha256 => "e1884d0fa1eec8cf869ac6bebbf25391e81956aa2970267f974a9fa5e0b968e2"

relative_path "libyaml-#{version}"

env = with_embedded_path()
env = with_standard_compiler_flags(env)

build do
  ship_license "https://raw.githubusercontent.com/yaml/libyaml/master/LICENSE"
  command "./bootstrap"
  command "./configure --prefix=#{install_dir}/embedded", :env => env
  command "make -j #{workers}", :env => env
  command "make -j #{workers} install", :env => env
end
