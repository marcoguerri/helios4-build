FROM archlinux/base
MAINTAINER Marco Guerri

# Running this container:
# sudo docker run --security-opt apparmor:unconfined --device-cgroup-rule="b 7:* rmw" --cap-add SYS_ADMIN --user root -ti helios4

# Requirements:
# * CAP_MKNOD to run mknod for loop device, assigned by default
# (note that the device created will be visible to the host).
# --partscan will not work automatically in the container
# (hence losetup with the offset pointing to the partition directly)
# * "b 7:99 rmw" in devices.allow to run ioctl LOOP_SET_FD
# * CAP_SYS_ADMIN to run mount
# * Relax seccomp profile to be able to mount rw (TODO: do more 
# fine grained tuning of the profile).


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
