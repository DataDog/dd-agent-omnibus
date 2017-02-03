def validate_manifest(manifest_hash)
  puts manifest_hash
  raise "manifest.json needs a manifest_version field" unless manifest_hash.key?("manifest_version")
  validate_manifest_version = manifest_hash["manifest_version"].gsub! '.', '_'
  send("validate_manifest_#{validate_manifest_version}", manifest_hash)
  puts "manifest is valid"
end

def validate_manifest_0_1_0(manifest_hash)
  mandatory_fields = [
    "maintainer",
    "manifest_version",
    "max_agent_version",
    "min_agent_version",
    "name",
    "short_description",
    "support",
    "version",
  ]
  mandatory_fields.each do |field|
    raise "manifest.json needs proper fields, currently missing #{field}. Please refer to documentation" unless manifest_hash.key?(field)
  end
end

def validate_manifest_0_1_2(manifest_hash)
  mandatory_fields = [
    "maintainer",
    "manifest_version",
    "max_agent_version",
    "min_agent_version",
    "name",
    "short_description",
    "support",
    "version",
  ]
  mandatory_fields.each do |field|
    raise "manifest.json needs proper fields, currently missing #{field}. Please refer to documentation" unless manifest_hash.key?(field)
  end
end