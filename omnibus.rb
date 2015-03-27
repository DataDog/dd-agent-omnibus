bucket = ENV['S3_OMNIBUS_BUCKET']

if bucket.nil? || bucket.empty?
  use_s3_caching false
else
  s3_access_key ENV['S3_ACCESS_KEY']
  s3_secret_key ENV['S3_SECRET_KEY']
  s3_bucket ENV['S3_OMNIBUS_BUCKET']
  use_s3_caching true
end

sign_pkg true
signing_identity 'Developer ID Installer: Datadog, Inc. (JKFCB4CN7C)'

