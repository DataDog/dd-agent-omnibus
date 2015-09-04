# Invalidate Objects from CloudFront

This tool lists all objects in an S3 bucket and identifies any objects that dont have version
numbers in their file name.  It then invalidates those objects from the specified cloudfront cache.

## Requirements

* Ruby 2.x
* AWS IAM Keys with access to s3:listbucket for the buckets of interest and CreateInvalidation for
the cloudfront buckets of interest.

## Install

* bundle install

## Usage

invalidate.rb accepts the following options:
Options:
  -a, --aws-key=<s>         AWS Public Key
  -w, --aws-secret=<s>      AWS Secret Key
  -b, --bucket=<s>          S3 Bucket to check for objects
  -d, --distribution=<s>    Cloudfront distribution to invalidate from
  -h, --help                Show this message

It will also respect AWS_SECRET_ACCESS_KEY and AWS_ACCESS_KEY_ID environment variables, if they
are set.
