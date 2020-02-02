# helios4-build

helios4-build implements an Arch Linux based Docker container which builds an Arch Linux image
for the Helios4 board. The build logic is based on [Gontran Baerts](https://github.com/gbcreation/alarm-helios4-image-builder) build script.

# Requirements
Docker daemon must be running and the system must support loop devices.

# Usage
The main entry point is `run.sh`, which supports 3 commands:

* `./run.sh build`: builds the Docker container images
* `./run.sh run`: builds the Helios4 image using the Docker image produced
by `build` command. It supports also running an interactive shell
within the build environment
* `./run.sh all`: run both `build` and `run`

Once the image for the board has been built, it will be available under
/home/helios4 in the container. You can also re-run the container in 
interactive mode (`./run.sh run`) to manually inspect or grab the image.
