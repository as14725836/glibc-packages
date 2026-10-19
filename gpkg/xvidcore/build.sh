TERMUX_PKG_HOMEPAGE=https://www.xvid.com/
TERMUX_PKG_DESCRIPTION="High performance and high quality MPEG-4 library"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux-pacman"
TERMUX_PKG_VERSION=1.3.7
TERMUX_PKG_SRCURL=https://downloads.xvid.com/downloads/xvidcore-${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=abbdcbd39555691dd1c9b4d08f0a031376a3b211652c0d8b3b8aa9be1303ce2d
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
	export TERMUX_PKG_BUILDDIR="$TERMUX_PKG_BUILDDIR/build/generic"
	export TERMUX_PKG_SRCDIR="$TERMUX_PKG_BUILDDIR"

	# xvidcore 1.3.7 ships "typedef int bool;", which is a hard error once the
	# compiler defaults to C23. Pin the C dialect; nothing here needs C23.
	export CFLAGS="$CFLAGS -std=gnu17"
	# The i686 assembly uses text relocations, which the glibc loader rejects
	# anyway. See https://www.xvid.org/
	if [ "$TERMUX_ARCH" = "i686" ]; then
		TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" --disable-assembly"
	fi
}
