#!/bin/bash
set -eu

build() {
  cd /home/helios4
  [ "$(id -u)" -eq 0 ] || ( echo "Script should run as root" && exit 1 )
  findmnt /proc/sys/fs/binfmt_misc || mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
  if /home/helios4/build-archlinux-img-for-helios4.sh; then
    img_file=$(find /home/helios4 -name 'ArchLinuxARM-helios4*')
    echo "The image is ready! Check out ${img_file}"
    /bin/bash
  else
    echo "There was an error while building the image"
  fi
}

if [ "$(id -u)" -ne 0 ]; then
  echo "Re-running with sudo"
  exec sudo "$0" "$@"
fi

build=0
if [ -t 1 ]; then
  read -r -p "Continue with building Helios4 image? (will drop into shell otherwise) (y/n)?" choice
  case "$choice" in
    y|Y ) echo "Starting build"; build=1;;
    n|N ) echo "Skipping build"; build=0;;
    * ) echo "invalid";;
  esac
fi

if [ "${build}" -eq 1 ]; then
  build
else
  exec /bin/bash
fi
