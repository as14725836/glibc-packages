TERMUX_PKG_HOMEPAGE=https://www.theora.org/
TERMUX_PKG_DESCRIPTION="An open video codec developed by the Xiph.org"
TERMUX_PKG_LICENSE="BSD"
TERMUX_PKG_MAINTAINER="@termux-pacman"
TERMUX_PKG_VERSION=1.2.0
TERMUX_PKG_SRCURL=https://downloads.xiph.org/releases/theora/libtheora-${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=279327339903b544c28a92aeada7d0dcfd0397b59c2f368cc698ac56f515906e
TERMUX_PKG_DEPENDS="libogg-glibc, libvorbis-glibc"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="--disable-examples --disable-static"

termux_step_pre_configure() {
	# libtheora 1.2.0 enables assembly optimizations on 32-bit ARM
	# automatically, but they are not position independent and fail to link
	# against a glibc toolchain. See https://gitlab.xiph.org/xiph/theora/-/issues/2340
	if [[ "$TERMUX_ARCH" == "arm" ]]; then
		TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" --disable-asm"
	fi
}
