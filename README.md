# helios4-build

helios4-build is an Arch Linux Docker container which builds an Arch Linux image
for the Helios4 board. The build logic is based on [Gontran Baerts](https://github.com/gbcreation/alarm-helios4-image-builder) script with several changes on top:

* The build happens entirely in the container, loop devices are exposed directly from the underlying host
* The upstream Arch Linux ARM kernel is used (linux-armv7). This means that some of
the custom patches that the [original build script would include](https://github.com/gbcreation/alarm-helios4-image-builder)
are not supported anymore, as they have not been upstreamed yet (kernel version at the
time of writing is 5.8.2). The patches are the following:
  * [91-01-libata-add-ledtrig-support.patch](https://github.com/armbian/build/blob/main/patch/kernel/archive/mvebu-6.1/91-01-libata-add-ledtrig-support.patch): adds support for disk activity LEDs
  * [91-02-Enable-ATA-port-LED-trigger.patch](https://github.com/armbian/build/blob/main/patch/kernel/archive/mvebu-6.6/91-02-Enable-ATA-port-LED-trigger.patch): enables support for disk activity LEDs via `ARCH_WANT_LIBATA_LEDS`
  * [92-mvebu-gpio-remove-hardcoded-timer-assignment.patch](https://github.com/armbian/build/blob/main/patch/kernel/archive/mvebu-6.6/92-mvebu-gpio-remove-hardcoded-timer-assignment.patch): in-kernel support for second fan. *This means that PWM control for second fan will not work (i.e. `/dev/fan-j17/pwm1` will not be present), and `/etc/fancontrol` has been configured accordingly. The board will be loud.*
  * [92-mvebu-gpio-add_wake_on_gpio_support.patch](https://github.com/armbian/build/blob/main/patch/kernel/archive/mvebu-6.6/92-mvebu-gpio-add_wake_on_gpio_support.patch): supports for Wake-On-Lan
  * [94-helios4-dts-add-wake-on-lan-support.patch](https://github.com/armbian/build/blob/main/patch/kernel/archive/mvebu-6.1/94-helios4-dts-add-wake-on-lan-support.patch): device tree changes to support Wake-On-Lan

Note that armbian is maintaining even more [kernel patches](https://github.com/armbian/build/tree/master/patch/kernel/mvebu-current) for Marvell Boards, some of which do apply to helios4 (and are not part of the list above). So, additional funcionalities might not be available.

# Why build an image with partial support for the board?
I use helios4 in a way that I can afford lack of the functionalities above, while I maintain complete tracking of upstream rolling releases cycles, which I do care a lot about.

# Requirements
Docker daemon must be running and the system must support loop devices.

# Usage
The main entry point is `run.sh`, which requires a command as argument. It should be invoked with root privileges. 
Supported commands are the following:

* `build`: builds the Docker image
* `run`: builds the Helios4 image using the Docker image produced
by `build` command. It supports also running an interactive shell
within the build environment
* `all`: run both `build` and `run`


> **Warning:** `run.sh` requires superuser permissions as it assumes the docker 
daemon is running as root. The large majority of the logic is executed in the container,
so it should be fairly easy to review `run.sh` and decide if you are happy to run it as
root. Do so at your own risk. The container itself needs to run in the host user namespace 
with `CAP_SYS_ADMIN` as it requires privileges to mount loop devices and `binfmt_misc` filesystem 
(it would not be possible with `userns-remap`). 

Once the image for the board has been built, it will be available as an `.img` file under
`/home/helios4` in the container. You can also re-run the container in 
interactive mode (`./run.sh run`) to manually inspect or grab the image.
