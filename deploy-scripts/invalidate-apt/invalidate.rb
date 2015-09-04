#!/usr/bin/env ruby

require 'cloudfront-invalidator'
require 'aws-sdk'
require 'trollop'

opts = Trollop::options do
  opt :aws_key, "AWS Public Key",  :type => :string, :default => ENV['AWS_ACCESS_KEY_ID']
  opt :aws_secret, "AWS Secret Key",  :type => :string, :default => ENV['AWS_SECRET_ACCESS_KEY']
  opt :bucket, "S3 Bucket to check for objects",  :type => :string, :default => nil
  opt :distribution, "Cloudfront distribution to invalidate from",  :type => :string, :default => nil
end

Trollop::die :aws_key, "You must specify AWS credentials" if opts[:aws_key].nil?
Trollop::die :aws_secret, "You must specify AWS credentials" if opts[:aws_secret].nil?
Trollop::die :bucket, "You must specify a bucket" if opts[:bucket].nil?
Trollop::die :distribution, "You must specify a cloudfront distribution" if opts[:distribution].nil?

Aws.config.update(region: 'us-east-1',
                  credentials: Aws::Credentials.new(opts[:aws_key], opts[:aws_secret]))

s3 = Aws::S3::Resource.new

objects = []
s3.bucket(opts[:bucket]).objects.each do |obj|
  objects.push('/' + obj.key) if obj.key.split('/').last !~ /[0-9]/
end

invalidator = CloudfrontInvalidator.new(opts[:aws_key], opts[:aws_secret], opts[:distribution])
invalidator.invalidate(objects)
