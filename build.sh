#!/bin/bash
set -eux

[ $(id -u) -eq 0 ] || ( echo "Script should run as root" && exit 1 )

findmnt /proc/sys/fs/binfmt_misc || mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
./build-archlinux-img-for-helios4.sh
