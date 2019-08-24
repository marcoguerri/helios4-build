FROM archlinux/base
MAINTAINER Marco Guerri

RUN useradd -m helios4

RUN pacman -Syu --noconfirm \
	git \
	gcc \
	make \
	fakeroot \
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
	diffutils 

RUN echo "helios4 ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN echo "39d200b8c2d141f5b0d266e40973b23f" > /etc/machine-id

RUN sed 's/.*MAKEFLAGS.*/MAKEFLAGS="-j4"/' -i /etc/makepkg.conf 

RUN mknod /dev/loop0 b 7 0

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
	git clone https://github.com/marcoguerri/alarm-helios4-image-builder.git && \
	cd alarm-helios4-image-builder && \
	./build-archlinux-img-for-helios4.sh
