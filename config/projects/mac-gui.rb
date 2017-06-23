require "./lib/ostools.rb"

name 'mac-gui'
if windows?
  # Windows doesn't want our e-mail address :(
  maintainer 'Datadog Inc.'
else
  maintainer 'Datadog Packages <package@datadoghq.com>'
end
homepage 'http://www.datadoghq.com'

if ohai['platform'] == "windows"
  # Note: this is not the final install dir, not even the default one, just a convenient
  # spaceless dir in which the agent will be built.
  # Omnibus doesn't quote the Git commands it launches unfortunately, which makes it impossible
  # to put a space here...
  install_dir "C:/opt/datadog-agent/"
else
  install_dir '/opt/datadog-agent-gui'
end

build_version do
  source :git, from_dependency: 'datadog-agent'
  output_format :dd_agent_format
end

build_iteration 1

description 'Datadog Monitoring Agent
 The Datadog Monitoring Agent is a lightweight process that monitors system
 processes and services, and sends information back to your Datadog account.
 .
 This package installs and runs the advanced Agent daemon, which queues and
 forwards metrics from your applications as well as system services.
 .
 See http://www.datadoghq.com/ for more information
'

# ------------------------------------
# Generic package information
# ------------------------------------

# .deb specific flags
package :deb do
  vendor 'Datadog <info@datadoghq.com>'
  epoch 1
  license 'Simplified BSD License'
  section 'utils'
  priority 'extra'
end

# .rpm specific flags
package :rpm do
  vendor 'Datadog <package@datadoghq.com>'
  epoch 1
  dist_tag ''
  license 'Simplified BSD License'
  category 'System Environment/Daemons'
  priority 'extra'
  if ENV.has_key?('RPM_SIGNING_PASSPHRASE') and not ENV['RPM_SIGNING_PASSPHRASE'].empty?
    signing_passphrase "#{ENV['RPM_SIGNING_PASSPHRASE']}"
  end
end

if redhat?
  runtime_dependency 'initscripts'
end

# OSX .pkg specific flags
package :pkg do
  identifier 'com.datadoghq.agent'
  signing_identity 'Developer ID Installer: Datadog, Inc. (JKFCB4CN7C)'
end
compress :dmg do
  window_bounds '200, 200, 750, 600'
  pkg_position '10, 10'
end

# Windows .msi specific flags
package :msi do
  # previous upgrade code was used for older installs, and generated
  # per-user installs.  Changing upgrade code, and switching to
  # per-machine
  per_user_upgrade_code = '82210ed1-bbe4-4051-aa15-002ea31dde15'

  # For a consistent package management, please NEVER change this code
  upgrade_code '0c50421b-aefb-4f15-a809-7af256d608a5'
  bundle_msi true
  bundle_theme true
  wix_candle_extension 'WixUtilExtension'
  wix_light_extension 'WixUtilExtension'
  if ENV['SIGN_WINDOWS']
    signing_identity "ECCDAE36FDCB654D2CBAB3E8975AA55469F96E4C", machine_store: true, algorithm: "SHA256"
  end
  parameters({
    'InstallDir' => install_dir,
    'InstallFiles' => "#{Omnibus::Config.source_dir()}/datadog-agent/dd-agent/packaging/datadog-agent/win32/install_files",
    'DistFiles' => "#{Omnibus::Config.source_dir()}/datadog-agent/dd-agent/dist",
    'PerUserUpgradeCode' => per_user_upgrade_code
  })
end
# Note: this is to try to avoid issues when upgrading from an
# old version of the agent which shipped also a datadog-agent-base
# package.
if redhat?
  replace 'datadog-agent-base < 5.0.0'
  replace 'datadog-agent-lib < 5.0.0'
elsif debian?
  replace 'datadog-agent-base (<< 5.0.0)'
  replace 'datadog-agent-lib (<< 5.0.0)'
  conflict 'datadog-agent-base (<< 5.0.0)'
end

# ------------------------------------
# OS specific DSLs and dependencies
# ------------------------------------

# creates required build directories - has to be the first declared dep
dependency 'preparation'

dependency 'mac-gui'

# version manifest file
# should be built after all the other dependencies
dependency 'version-manifest'

exclude '\.git*'
exclude 'bundler\/git'
