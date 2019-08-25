FROM archlinux/base
MAINTAINER Marco Guerri

# Notes:
# CAP_MKNOD seems to be assigned by default, there is no need for
# additional flags for docker run to get device file creation
# capabilities. 
# However, the device file created with mknod will map to
# a device file on the host if the correct major and minor are
# provided. The kernel will forbid access unless the device is
# in the device.allow list of the cgroup (CAP_SYS_ADMIN doesn't
# seem to be enough?) Furthermore, upon partition rescanning, the 
# additional device files will not be visible inside the 
# container (mknod would not work for the reason above?)

# The only way I could make this work was by run 
# the container in --privileged mode with -v /dev:/dev

# Requires also
# sudo mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc

RUN useradd -m helios4

RUN pacman -Syu --noconfirm \
	bc \
	git \
	gcc \
	bison \
	make \
	fakeroot \
	flex \
	sudo \
	binutils \
	awk \
	patch \
	file \
	libffi \
	pkg-config \
	shared-mime-info \
	python \
	meson \
	libxslt \
	docbook-xsl \
	desktop-file-utils \
	wget \
	python2 \
	diffutils \
	which \
	aria2

RUN echo "helios4 ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN echo "39d200b8c2d141f5b0d266e40973b23f" > /etc/machine-id

RUN sed 's/.*MAKEFLAGS.*/MAKEFLAGS="-j4"/' -i /etc/makepkg.conf 

USER helios4

RUN cd $HOME &&  \
	git clone https://aur.archlinux.org/pcre-static.git &&  \
	cd pcre-static &&  \
	makepkg -i --skippgpcheck --noconfirm || true

RUN cd $HOME &&  \
	git clone https://aur.archlinux.org/glib2-static.git && \
	cd glib2-static &&  \
	makepkg -i --skippgpcheck --noconfirm ||  true 

RUN cd $HOME &&  \
	git clone https://aur.archlinux.org/qemu-user-static.git && \
	cd qemu-user-static &&  \
	makepkg -i --skippgpcheck --noconfirm ||  true 

RUN cd $HOME && \
	git clone https://github.com/marcoguerri/alarm-helios4-image-builder.git
