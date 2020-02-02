# helios4-build

helios4-build implements an Arch Linux based Docker container which builds an Arch Linux image
for the Helios4 board. The build logic is based on [Gontran Baerts](https://github.com/gbcreation/alarm-helios4-image-builder) build script.

# Requirements
Docker daemon must be running and the system must support loop devices.

# Usage
The main entry point is `run.sh`, which supports 3 commands:

* `sudo ./run.sh build`: builds the Docker container images
* `sudo ./run.sh run`: builds the Helios4 image using the Docker image produced
by `build` command. It supports also running an interactive shell
within the build environment
* `sudo ./run.sh all`: run both `build` and `run`


> **Warning:** `run.sh` requires superuser permissions as it assumes the docker 
daemon is running as root. The large majority of the logic is executed in the container,
so it should be fairly easy to review `run.sh` and decide if you are happy to run it as
root. Do so at your own risk. The container itself needs to run in the host user namespace 
as it requires privileges to mount loop devices and `binfmt_misc` filesystem 
(it would not be possible with `userns-remap`). 

Once the image for the board has been built, it will be available as an `.img` file under
`/home/helios4` in the container. You can also re-run the container in 
interactive mode (`./run.sh run`) to manually inspect or grab the image.
