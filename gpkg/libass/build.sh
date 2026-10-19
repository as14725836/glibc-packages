TERMUX_PKG_HOMEPAGE=https://github.com/libass/libass
TERMUX_PKG_DESCRIPTION="A portable library for SSA/ASS subtitles rendering"
TERMUX_PKG_LICENSE="BSD"
TERMUX_PKG_MAINTAINER="@termux-pacman"
TERMUX_PKG_VERSION="0.17.5"
TERMUX_PKG_SRCURL=https://github.com/libass/libass/releases/download/$TERMUX_PKG_VERSION/libass-$TERMUX_PKG_VERSION.tar.xz
TERMUX_PKG_SHA256=2dca25c0e0c837ddf00b52011b3f82cac1e4ddd3ad018227806b0c2288864acc
TERMUX_PKG_DEPENDS="fontconfig-glibc, fribidi-glibc, freetype-glibc, harfbuzz-glibc"
# Avoid text relocations.
TERMUX_PKG_EXTRA_CONFIGURE_ARGS=" ac_cv_prog_nasm_check=no --disable-libunibreak --disable-test --disable-compare"
termux_step_post_get_source() {
	# Do not forget to bump revision of reverse dependencies and rebuild them
	# after SOVERSION is changed.
	local _SOVERSION=9
	local current=$(sed -En 's/^LIBASS_LT_CURRENT\s*=\s*([0-9]+).*/\1/p' libass/Makefile_library.am)
	local age=$(sed -En 's/^LIBASS_LT_AGE\s*=\s*([0-9]+).*/\1/p' libass/Makefile_library.am)
	local v=$(( current - age ))
	if [ -z "${current}" ] || [ -z "${age}" ] || [ "${v}" != "${_SOVERSION}" ]; then
		termux_error_exit "SOVERSION guard check failed. Expected ${_SOVERSION}, got ${v}."
	fi
}
