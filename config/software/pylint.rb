name "pylint"
# Ship 1.x as 2.x only supports python 3
default_version "1.9.6"

dependency "pip"

build do
  # pylint is only called in a subprocess by the Agent, so the Agent doesn't have to be GPL as well
  ship_license "GPLv2"

  # this pins a dependency of pylint, later versions (up to v3.7.1) are broken.
  pip "install configparser==3.5.0"
  pip "install pylint==#{version}"
end
