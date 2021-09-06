source 'https://rubygems.org'

# These gems are no longer compatible with ruby 2.2.0 in their latest versions:
# we need to pin them
gem 'toml-rb', '~> 1.1.2'
gem 'license_scout', '~> 1.0.0'
gem 'aws-eventstream', '~> 1.1.1'
gem 'aws-sigv4', '~> 1.2.4'

# we default if env variable aren't set or set to an empty string
gem 'omnibus', git: 'git://github.com/datadog/omnibus-ruby.git', branch: (if ENV['OMNIBUS_RUBY_BRANCH'].to_s.empty? then 'datadog-5.5.0' else ENV['OMNIBUS_RUBY_BRANCH'] end)
gem 'omnibus-software', git: 'git://github.com/datadog/omnibus-software.git', branch: (if ENV['OMNIBUS_SOFTWARE_BRANCH'].to_s.empty? then 'master' else ENV['OMNIBUS_SOFTWARE_BRANCH'] end)

gem 'httparty'
gem 'win32-process'
gem 'ohai'
gem 'pedump', '~> 0.5.0'
gem 'rake', '~> 12.3'

# We need an older version of mixlib-cli on our version of ruby
gem 'mixlib-cli', '~> 1.7.0'
gem 'public_suffix', '~>3.0.3'
