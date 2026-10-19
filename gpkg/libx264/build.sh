TERMUX_PKG_HOMEPAGE=https://www.videolan.org/developers/x264.html
TERMUX_PKG_DESCRIPTION="Library for encoding video streams into the H.264/MPEG-4 AVC format"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux-pacman"
_COMMIT=4613ac3c15fd75cebc4b9f65b7fb95e70a3acce1
# X264_BUILD from x264.h; commit count using "git rev-list --count HEAD" on x264 git repo
TERMUX_PKG_VERSION=0.164.3191
TERMUX_PKG_SRCURL=https://code.videolan.org/videolan/x264/-/archive/${_COMMIT}/x264-${_COMMIT}.tar.bz2
TERMUX_PKG_SHA256=2a1b197fd1fbc85045794f18c9353648a9ae3cbe194b7b92d523d096f9445464
# Avoid linking against ffmpeg libraries to avoid a circular dependency:
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--disable-lavf
--disable-swscale
--disable-cli
--enable-shared
--disable-static
"

termux_step_pre_configure() {
	# x264 assembles its NEON sources with $(AS). The CGCT environment points
	# AS at the bare GNU assembler, which does not understand the -D/-I flags
	# x264 passes to it, so use the compiler driver like clang builds do.
	export AS="$CC"
	# x264 requires nasm for its x86 assembly, which the glibc repositories
	# do not ship. aarch64/arm NEON code is written in gas and works fine.
	if [ "$TERMUX_ARCH" = "i686" ] || [ "$TERMUX_ARCH" = "x86_64" ]; then
		TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" --disable-asm"
	fi
}
termux_step_post_massage() {
	# x264 has no stable soname guard upstream; keep an explicit check so a
	# silent SOVERSION change does not slip into a release.
	local _SOVERSION=164
	if [ ! -e "glibc/lib/libx264.so.${_SOVERSION}" ]; then
		termux_error_exit "libx264.so.${_SOVERSION} not found; please check if SOVERSION has changed."
	fi
}
