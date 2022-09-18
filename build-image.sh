#!/bin/bash
#
# Bash script creating an Arch Linux ARM image for the Helios4 NAS.
#
# Author: Gontran Baerts
# Repository: https://github.com/gbcreation/linux-helios4
# License: MIT
#
# Adapted by Marco Guerri for https://github.com/marcoguerri/helios4-build
#

set -eu

# Configuration
DOWNLOADER="aria2c --continue=true -x 4"
IMG_DIR="./"
IMG_DIR=`readlink -f "${IMG_DIR}"`
IMG_FILE="ArchLinuxARM-helios4-$(date +%Y-%m-%d).img"
IMG_SIZE="4G"
MOUNT_DIR="./img"

ALARM_ROOTFS="http://os.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz"
SIG_FILE="ArchLinuxARM-armv7-latest.tar.gz.sig"
ALARM_SIG="http://os.archlinuxarm.org/os/${SIG_FILE}"
GPG_KEY="68B3537F39A313B3E574D06777193F152BDBE6A6"

LINUX_HELIOS4_VERSION=`wget -q -O - https://api.github.com/repos/gbcreation/linux-helios4/releases/latest | sed -En '/tag_name/{s/.*"([^"]+)".*/\1/;p}'`

sources=(
        'https://raw.githubusercontent.com/armbian/build/master/packages/bsp/mvebu/helios4/90-helios4-hwmon.rules'
        'https://raw.githubusercontent.com/armbian/build/master/packages/bsp/mvebu/helios4/mdadm-fault-led.sh'
        'https://raw.githubusercontent.com/armbian/build/master/packages/bsp/mvebu/helios4/helios4-wol.service'
)
md5sums=(
         'c25794873ebcd50405c591a09efa0aaa'
         'f8ba1994cfd5af8e546dda12308da41d'
         '4b37a9a91b69695747ef2c6b0d01fa98'
)

echo_step () {
    echo -e "\e[1;32m ${@} \e[0m\n"
}


echo_step "\nArchLinux ARM image builder for Helios4 NAS"

which qemu-arm-static >/dev/null 2>&1 || {
    echo 'This script needs qemu-arm-static to work. Install qemu-user-static or qemu-user-static-bin from the AUR.'
    exit 1
}

if [[ $EUID != 0 ]]; then
    echo This script requires root privileges, trying to use sudo
    sudo "$0"
    exit $?
fi

echo_step Install script dependencies...
pacman -Sy --needed --noconfirm arch-install-scripts arm-none-eabi-gcc uboot-tools

echo_step "\nDownloading rootfs"

gpg --keyserver keyserver.ubuntu.com --recv-keys ${GPG_KEY}

echo_step "\nVerifying signature of rootfs"

${DOWNLOADER} "${ALARM_ROOTFS}"
${DOWNLOADER} "${ALARM_SIG}"

gpg --verify "${SIG_FILE}"

for i in ${!sources[*]}; do
    echo_step Download ${sources[i]}...
    ${DOWNLOADER} "${sources[i]}"
    if [ "`md5sum ${sources[i]##*/} | cut -d ' ' -f1`" != "${md5sums[i]}" ]; then
        echo Wrong MD5 sum for ${sources[i]}.
        exit 1
    fi
done

echo_step Create ${IMG_DIR}/${IMG_FILE} image file...
dd if=/dev/zero of="${IMG_DIR}/${IMG_FILE}" bs=1 count=0 seek=${IMG_SIZE}

echo_step Create partition...
fdisk "${IMG_DIR}/${IMG_FILE}" <<EOF
o
n
p
1


w
EOF

LOOP_DEV_NO=$(losetup -f | tr -c -d [0-9])
LOOP_DEV_PART_NO=$((${LOOP_DEV_NO}+1))
LOOP_DEV="/dev/loop${LOOP_DEV_NO}"
LOOP_DEV_PART="/dev/loop${LOOP_DEV_PART_NO}"

echo_step Mount loop image...

umount -R "${MOUNT_DIR}" > /dev/null 2>&1 || true

losetup -D || true
[[ -e "${LOOP_DEV_PART}" ]] || ( echo "No loop dev part available" && exit 1 )
[[ -e "${LOOP_DEV}" ]] || ( echo "No device loop device available" && exit 1 )

losetup "${LOOP_DEV}" ${IMG_DIR}/${IMG_FILE}
losetup -o1048576 "${LOOP_DEV_PART}" "${IMG_DIR}/${IMG_FILE}"

echo_step Format partition ${LOOP_DEV_PART}
mkfs.ext4 -qF -L alarm-helios4 "${LOOP_DEV_PART}"

echo_step Mount image partition ${LOOP_DEV_PART} to ${MOUNT_DIR}...
mkdir -p "${MOUNT_DIR}"
mount "${LOOP_DEV_PART}" "${MOUNT_DIR}"

echo_step Extract ${ALARM_ROOTFS##*/} to ${MOUNT_DIR}...
bsdtar -xpf "${ALARM_ROOTFS##*/}" -C "${MOUNT_DIR}"

echo_step Copy hwmon to fix device mapping...
sed -e 's/armada_thermal/f10e4078.thermal/' 90-helios4-hwmon.rules > ${MOUNT_DIR}/etc/udev/rules.d/90-helios4-hwmon.rules

echo_step Copy helios4-wol.service to ${MOUNT_DIR}/usr/lib/systemd/system/...
cp helios4-wol.service ${MOUNT_DIR}/usr/lib/systemd/system/

echo_step Copy `which qemu-arm-static` to ${MOUNT_DIR}/usr/bin...
cp `which qemu-arm-static` ${MOUNT_DIR}/usr/bin

echo_step Register qemu-arm-static as ARM interpreter in the kernel...
[ ! -f /proc/sys/fs/binfmt_misc/arm ] && echo ':arm:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-arm-static:CF' > /proc/sys/fs/binfmt_misc/register

echo_step Initialize pacman-key, update ARM system and install lm_sensors...
arch-chroot ${MOUNT_DIR} bash -c "
    pacman-key --init &&
    pacman-key --populate archlinuxarm &&
    pacman -Syu --noconfirm &&
    pacman -S --noconfirm lm_sensors ethtool &&
    systemctl enable fancontrol.service &&
    systemctl --no-reload enable helios4-wol.service &&
    echo helios4 > /etc/hostname
"

echo_step Remove qemu-arm-static from ${MOUNT_DIR}/usr/bin...
rm -f ${MOUNT_DIR}/usr/bin/qemu-arm-static

echo_step Copy fancontrol config...
cp fancontrol_pwm-fan.conf ${MOUNT_DIR}/etc/fancontrol

echo_step Configure loading of lm75 kernel module on boot...
echo "lm75" > ${MOUNT_DIR}/etc/modules-load.d/lm75.conf

echo_step Copy mdadm-fault-led script and modify mdadm configuration...
cp mdadm-fault-led.sh ${MOUNT_DIR}/usr/sbin
echo "PROGRAM /usr/sbin/mdadm-fault-led.sh" >> ${MOUNT_DIR}/etc/mdadm.conf

echo_step Copy u-boot boot.cmd to ${MOUNT_DIR}/boot...
cat << 'EOF' > "${MOUNT_DIR}/boot/boot.cmd"
setenv eth1addr "00:50:43:25:fb:84"
part uuid ${devtype} ${devnum}:${bootpart} uuid
setenv bootargs console=${console} root=PARTUUID=${uuid} rw rootwait loglevel=1
load ${devtype} ${devnum}:${bootpart} ${kernel_addr_r} /boot/zImage
load ${devtype} ${devnum}:${bootpart} ${fdt_addr_r} /boot/dtbs/${fdtfile}
load ${devtype} ${devnum}:${bootpart} ${ramdisk_addr_r} /boot/initramfs-linux.img
bootz ${kernel_addr_r} ${ramdisk_addr_r}:${filesize} ${fdt_addr_r}
EOF

echo_step Compile boot.cmd...
mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "Helios4 boot script" -d "${MOUNT_DIR}/boot/boot.cmd" "${MOUNT_DIR}/boot/boot.scr"

echo_step Unmount image partition...
sync
umount "${MOUNT_DIR}"

echo_step Build U-Boot...
[ ! -d "u-boot" ] && git clone --depth=1 https://github.com/helios-4/u-boot.git -b helios4 && (cd u-boot && patch -p1 < ../0001-Fix-build-gcc-10.patch)
cd u-boot
[ ! -f u-boot-spl.kwb ] && {
    export ARCH=arm
    export CROSS_COMPILE=arm-none-eabi-
    make mrproper
    make helios4_defconfig
    make -j4
}

echo_step Copy u-boot to ${LOOP_DEV}...
dd if=u-boot-spl.kwb of="${LOOP_DEV}" bs=512 seek=1
cd -

echo_step Unmount loop partition...
sync
losetup -d "${LOOP_DEV_PART}"
losetup -d "${LOOP_DEV}"

echo_step done
