TERMUX_PKG_HOMEPAGE=https://github.com/webmproject/libwebp
TERMUX_PKG_DESCRIPTION="Library to encode and decode images in WebP format"
TERMUX_PKG_LICENSE="BSD 3-Clause"
TERMUX_PKG_MAINTAINER="@termux-pacman"
TERMUX_PKG_VERSION=1.6.0
TERMUX_PKG_SRCURL="https://github.com/webmproject/libwebp/archive/refs/tags/v${TERMUX_PKG_VERSION}.tar.gz"
TERMUX_PKG_SHA256=93a852c2b3efafee3723efd4636de855b46f9fe1efddd607e1f42f60fc8f2136
TERMUX_PKG_DEPENDS="giflib-glibc, libjpeg-turbo-glibc, libpng-glibc, libtiff-glibc, zlib-glibc"
TERMUX_PKG_FORCE_CMAKE=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DBUILD_SHARED_LIBS=ON
-DWEBP_BUILD_ANIM_UTILS=ON
-DWEBP_BUILD_CWEBP=ON
-DWEBP_BUILD_DWEBP=ON
-DWEBP_BUILD_GIF2WEBP=ON
-DWEBP_BUILD_IMG2WEBP=ON
-DWEBP_BUILD_WEBPMUX=ON
-DWEBP_BUILD_EXTRAS=ON
-DWEBP_BUILD_VWEBP=OFF
-DWEBP_ENABLE_SWAP_16BIT_CSP=ON
"

termux_step_post_get_source() {
	# Do not forget to bump revision of reverse dependencies and rebuild them
	# after SOVERSION is changed.
	local _SOVERSION=7
	local e=$(sed -En 's/^libwebp_la_LDFLAGS\s*=.*\s+-version-info\s+([0-9]+):([0-9]+):([0-9]+).*/\1-\3/p' \
		src/Makefile.am)
	if [ ! "${e}" ] || [ "${_SOVERSION}" != "$(( "${e}" ))" ]; then
		termux_error_exit "SOVERSION guard check failed. Expected ${_SOVERSION}, got '${e}'."
	fi
}
