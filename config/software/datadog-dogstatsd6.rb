name "datadog-dogstatsd6"

agent6_branch = ENV['AGENT6_BRANCH']
if agent6_branch.nil? || agent6_branch.empty?
  agent6_branch = 'master'
end
default_version agent6_branch

if linux?
  dsd6 = "dogstatsd6-linux-amd64-#{version}"
elsif windows?
  dsd6 = "dogstatsd6-win-amd64-#{version}"
elsif darwin?
  dsd6 = "dogstatsd6-darwin-amd64-#{version}"
else
  fail "unsupported platform for dsd6"
end

source :url => "https://s3.amazonaws.com/dd-agent/dsd6/#{dsd6}"

version "beta" do
  if linux?
    source :sha256 => "2422486aa9edb9dbfd0c7dfaf8795069f2d87b568cb2e210cffca35e5a2fcbb9"
  end
end

build do
   ship_license "https://raw.githubusercontent.com/DataDog/datadog-agent/#{version}/LICENSE"

  command "chmod +x #{dsd6}"
  copy "#{dsd6}", "#{install_dir}/bin/dogstatsd6"
end
