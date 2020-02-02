#!/bin/bash

set -eu

fail () {
  echo "$@";
  exit 1;
}


if [ "$(id -u)" != 0 ]; then
  echo "This script requires sudo privileges, re-running with sudo..."
  exec sudo "$0" "$@"
fi

# Make sure that we have the expected number of arguments
if [ $# -ne 1 ]; then
  fail "Usage: $0 <build|run|all>"
fi

if [ "$1" != "build" ] && [ "$1" != "run" ] && [ "$1" != "all" ]; then
  fail "Command $1 not supported"
fi

if [ "$1" = "build" ] || [ "$1" = "all" ] ; then
  echo "Stopping and removing already existing containers..."
  ( 
    docker stop c_helios4 && docker rm c_helios4  > /dev/null 2>&1
  )
  echo "Building container..."
  docker build --build-arg CACHE_DATE="$(date)" --cpuset-cpus 0-3 -t helios4 . || exit 1
fi

if [ "$1" = "run" ] || [ "$1" = "all" ]; then

  devno_dev=$(losetup -f | tr -c -d "[:digit:]")
  devno_part=$((devno_dev+1))

  losetup /dev/loop${devno_part} > /dev/null 2>&1 && \
    fail "/dev/loop${devno_part} is not available, " \
         "two consecutive loop devices are necessary"

  echo "Will use devices /dev/loop${devno_dev}, /dev/loop${devno_part}"

  if docker inspect c_helios4 > /dev/null 2>&1 ; then
    echo "Docker container already exists, restarting..."
    docker stop c_helios4
    docker start -ai c_helios4 
  else
    echo "Creating container..."
    docker run \
      --cap-drop MKNOD \
      --security-opt apparmor:unconfined \
      --device-cgroup-rule="b 7:${devno_dev} rmw" \
      --device-cgroup-rule="b 7:${devno_part} rmw" \
      -v /dev/loop"${devno_dev}":/dev/loop"${devno_dev}" \
      -v /dev/loop"${devno_part}":/dev/loop"${devno_part}" \
      --cap-add SYS_ADMIN -it --name c_helios4 helios4 \
      /home/helios4/build.sh
  fi

  (
    losetup -d /dev/loop"${devno_dev}" 2> /dev/null
    losetup -d /dev/loop"${devno_part}" 2> /dev/null
  )

  # Notes:
  # This container needs to have a loop device available and needs
  # to be able to loop mount a filesystem on that device.

  # Possible approaches:
  # * CAP_MKNOD is assigned by default to the container so
  # one could mknod directly inside the container
  # * --cap-drop MKNOD and instead loop mount a device file
  # into the container (e.g. -v /dev/loop0:/dev/loop0)

  # The container needs to be able to call ioctl LOOP_SET_FD on the 
  # loop device. The ACLs for the device are enforced by the
  # device.allow file of the container. To allow rwm access to
  # loop devices: --device-cgroup-rule="b 7:<loop_dev_no> rmw"
fi
