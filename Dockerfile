FROM archlinux
MAINTAINER Marco Guerri

RUN useradd -m helios4

RUN pacman-key --init
RUN pacman-key --populate archlinux
RUN pacman -Sy --noconfirm archlinux-keyring

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
	aria2 \
	gettext \
	qemu-user-static

RUN cat /proc/sys/kernel/random/uuid  | sed 's/-//g' > /etc/machine-id

RUN echo "helios4 ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN sed 's/.*MAKEFLAGS.*/MAKEFLAGS="-j4"/' -i /etc/makepkg.conf 

USER helios4

ARG CACHE_DATE=init

WORKDIR /home/helios4

COPY --chown=helios4:helios4 build-image.sh .
COPY --chown=helios4:helios4 scripts/build.sh .
COPY --chown=helios4:helios4 files .

RUN chmod u+x build.sh
