name "pyyaml"
default_version "5.3.1"

dependency "python"
dependency "pip"

if ohai["platform"] == "windows"
  dependency "libyaml-windows"
else
  dependency "libyaml"
end

build do
  ship_license "https://raw.githubusercontent.com/yaml/pyyaml/#{version}/LICENSE"
  pip "install --install-option=\"--install-scripts="\
      "#{windows_safe_path(install_dir)}/bin\" "\
      "#{name}==#{version}"

  # Patch applies to only one file: set it explicitly as a target, no need for -p
  if windows?
    patch :source => "create-regex-at-runtime.patch", :target => "#{install_dir}/embedded/Lib/site-packages/yaml/reader.py"
  else
    patch :source => "create-regex-at-runtime.patch", :target => "#{install_dir}/embedded/lib/python2.7/site-packages/yaml/reader.py"
  end
end
