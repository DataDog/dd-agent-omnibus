source 'https://rubygems.org'

# we default if env variable aren't set or set to an empty string
gem 'omnibus', git: 'git://github.com/datadog/omnibus-ruby.git', branch: (if ENV['OMNIBUS_RUBY_BRANCH'].to_s.empty? then 'datadog-5.5.0' else ENV['OMNIBUS_RUBY_BRANCH'] end)
gem 'omnibus-software', git: 'git://github.com/datadog/omnibus-software.git', branch: (if ENV['OMNIBUS_SOFTWARE_BRANCH'].to_s.empty? then 'master' else ENV['OMNIBUS_SOFTWARE_BRANCH'] end)

gem 'httparty'
gem 'win32-process'
gem 'ohai'
gem 'pedump', '~> 0.5.0'
gem 'rake', '~> 11.0'
