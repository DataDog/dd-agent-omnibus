# -*- mode: ruby -*-
# vi: set ft=ruby :

require "vagrant"

if Vagrant::VERSION < "1.2.1"
  raise "The Omnibus Build Lab is only compatible with Vagrant 1.2.1+"
end

host_project_path = File.expand_path("..", __FILE__)
guest_project_path = "/home/vagrant/#{File.basename(host_project_path)}"
project_name = "datadog-agent"

Vagrant.configure("2") do |config|

  config.vm.hostname = "#{project_name}-omnibus-build-lab.com"

  # Let's cache stuff to reduce build time using vagrant-cachier
  # Require vagrant-cachier plugin
  config.cache.scope = :box

 vms_to_use = {
    'ubuntu-i386' => 'ubuntu-10.04-i386',
    'ubuntu-x64' => 'ubuntu-10.04',
    'debian-i386' => 'debian-6.0.8-i386',
    'debian-x64' => 'debian-6.0.8',
    'fedora-i386' => 'fedora-19-i386',
    'fedora-x64' => 'fedora-19',
    'centos-i386' => 'centos-5.10-i386',
    'centos-x64' => 'centos-5.10',
    }

  vms_to_use.each_pair do |key, platform|

    config.vm.define key do |c|
      c.vm.box = "opscode-#{platform}"
      c.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_#{platform}_chef-provisionerless.box"
    end

  end

  config.vm.provider :virtualbox do |vb|
    # Give enough horsepower to build without taking all day.
    vb.customize [
      "modifyvm", :id,
      "--memory", "3072",
      "--cpus", "3",
      "--ioapic", "on" # Required for the centos-5-32 bits to boot
    ]
  end

  # Ensure a recent version of the Chef Omnibus packages are installed
  config.omnibus.chef_version = "11.12.8"

  # Enable the berkshelf-vagrant plugin
  config.berkshelf.enabled = true
  # The path to the Berksfile to use with Vagrant Berkshelf
  config.berkshelf.berksfile_path = "./Berksfile"

  config.ssh.forward_agent = true

  host_project_path = File.expand_path("..", __FILE__)
  guest_project_path = "/home/vagrant/#{File.basename(host_project_path)}"

  config.vm.synced_folder host_project_path, guest_project_path

  # prepare VM to be an Omnibus builder
  config.vm.provision :chef_solo do |chef|
    chef.custom_config_path = "Vagrantfile.chef"
    chef.json = {
      "omnibus" => {
        "build_user" => "vagrant",
        "build_dir" => guest_project_path,
        "install_dir" => "/opt/#{project_name}"
      },
      "go" => {
        "version" => "1.2.2"
      }
    }

    chef.run_list = [
      "recipe[omnibus::default]",
      "recipe[golang]"
    ]
  end

  unless "#{ENV['AGENT_LOCAL_REPO']}".empty?
    config.vm.synced_folder ENV['AGENT_LOCAL_REPO'], "/home/vagrant/dd-agent-repo"
    agent_repo = "/home/vagrant/dd-agent-repo"
  else
    agent_repo = "https://github.com/DataDog/dd-agent.git"
  end


  if ENV['CLEAR_CACHE'] == "true"
    config.vm.provision "shell",
      inline: "echo Clearing Omnibus cache && rm -rf /var/cache/omnibus/*"
  end


  config.vm.provision :shell, :inline => <<-OMNIBUS_BUILD
    export PATH=/usr/local/bin:$PATH
    export AGENT_VERSION=#{ENV['AGENT_VERSION']}
    export AGENT_BRANCH=#{ENV['AGENT_BRANCH']}
    export BUILD_NUMBER=#{ENV['BUILD_NUMBER']}
    export S3_ACCESS_KEY=#{ENV['S3_ACCESS_KEY']}
    export S3_SECRET_KEY=#{ENV['S3_SECRET_KEY']}
    export S3_OMNIBUS_BUCKET=#{ENV['S3_OMNIBUS_BUCKET']}
    export PKG_TYPE=#{ENV['PKG_TYPE']}
    export ARCH=#{ENV['ARCH']}
    export AGENT_REPO=#{agent_repo}
    export GPG_PASSPHRASE=#{ENV['GPG_PASSPHRASE']}
    export GPG_KEY_NAME=#{ENV['GPG_KEY_NAME']}
    rm -rf /var/cache/omnibus/pkg/*
    sudo rm -f /etc/init.d/datadog-agent
    sudo rm -rf /etc/dd-agent
    sudo rm -rf /opt/#{project_name}/*
    sudo rm -rf /tmp/pip_build_vagrant
    cd #{guest_project_path}
    su vagrant -c "bundle install --binstubs"
    su vagrant -c "bin/omnibus build -l=#{ENV['LOG_LEVEL']} #{project_name}"
    if [ #{ENV['PKG_TYPE']} == "rpm" ] && [ #{ENV['GPG_PASSPHRASE']} ] && [ #{ENV['GPG_KEY_NAME']} ]; then
        su vagrant -c "bin/rpm-sign #{ENV['GPG_KEY_NAME']} #{ENV['GPG_PASSPHRASE']} pkg/#{project_name}-#{ENV['AGENT_VERSION']}-#{ENV['BUILD_NUMBER']}.*.rpm"
    fi
  OMNIBUS_BUILD
end