name "psutil"
default_version "5.6.7"

dependency "python"
dependency "pip"

build do
  ship_license "https://raw.githubusercontent.com/giampaolo/psutil/master/LICENSE"
  pip "install --install-option=\"--install-scripts="\
      "#{windows_safe_path(install_dir)}/bin\" "\
      "#{name}==#{version}"
end
