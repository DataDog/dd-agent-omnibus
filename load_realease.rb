#!/usr/bin/env ruby

require 'json'

data = File.read("release.json")
versions = JSON.parse(data)

if ! ENV.key?("RELEASE_VERSION")
	abort("Error: RELEASE_VERSION environment variable is not set")
end

if ! versions.key?(ENV["RELEASE_VERSION"])
	abort("Error: version '#{ENV["RELEASE_VERSION"]}' does not exists in release.json")
end
release = versions[ENV["RELEASE_VERSION"]]

# checking that all mandatory variables are present in the release instead of
# failing later in the build
[
	"AGENT_VERSION",
	"AGENT_BRANCH",
	"AGENT6_BRANCH",
	"INTEGRATIONS_CORE_BRANCH",
	"TRACE_AGENT_BRANCH",
	"TRACE_AGENT_ADD_BUILD_VARS",
	"PROCESS_AGENT_BRANCH",
	"OMNIBUS_RUBY_BRANCH",
	"OMNIBUS_SOFTWARE_BRANCH",
].each do |var|
	if !release.key?(var)
		abort("Error: missing '#{var}' variable in the '#{ENV["RELEASE_VERSION"]}' release. Add it to the release.json file.")
	end
	if release[var] == "" or release[var].nil?
		abort("Error: variable '#{var}' in the '#{ENV["RELEASE_VERSION"]}' is empty.")
	end
end

# printing every variables so they can be easily loaded by omnibus_build.sh
release.each do |k, v| puts "#{k} #{v}" end
