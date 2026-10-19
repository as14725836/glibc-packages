TERMUX_PKG_HOMEPAGE=https://www.x265.org/
TERMUX_PKG_DESCRIPTION="H.265/HEVC video stream encoder library"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux-pacman"
TERMUX_PKG_VERSION="4.3"
TERMUX_PKG_SRCURL="https://github.com/Multicorewareinc/x265/releases/download/${TERMUX_PKG_VERSION}/x265_${TERMUX_PKG_VERSION}.tar.gz"
TERMUX_PKG_SHA256=83c53e4c8bbb8f1e33ed59e10a7d621d1d7801ca853910c3eb41f038b8ffb121
TERMUX_PKG_DEPENDS="gcc-libs-glibc"
TERMUX_PKG_FORCE_CMAKE=true
termux_step_post_get_source() {
	# Do not forget to bump revision of reverse dependencies and rebuild them
	# after SOVERSION is changed.
	local _SOVERSION=217
	local v=$(sed -En 's/^.*set\(X265_BUILD ([0-9]+).*$/\1/p' \
		source/CMakeLists.txt)
	if [ "${v}" != "${_SOVERSION}" ]; then
		termux_error_exit "SOVERSION guard check failed. Expected ${_SOVERSION}, got ${v}."
	fi
}
termux_step_pre_configure() {
	if [ "$TERMUX_ARCH" = arm ] || [ "$TERMUX_ARCH" = i686 ]; then
		# Avoid text relocations and/or build failure.
		TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DENABLE_ASSEMBLY=OFF"
	fi
	# The CMakeLists.txt of interest lives in the source/ subdirectory.
	TERMUX_PKG_SRCDIR="$TERMUX_PKG_SRCDIR/source"
}
termux_step_configure() {
	termux_setup_cmake
	termux_setup_ninja
	TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DENABLE_PIC=ON"
	if [ "$TERMUX_ARCH_BITS" = "32" ]; then
		# -DHIGH_BIT_DEPTH=ON and -DMAIN12=ON have no effect on 32-bit targets.
		pushd "$TERMUX_PKG_BUILDDIR"
		termux_step_configure_cmake
		popd
		return
	fi
	# Build 8, 10 and 12 bit depth modes into a single library, the same way
	# Arch Linux does it: the 10 and 12 bit static libraries are built first
	# and then linked into the final shared library.
	local _base_args="$TERMUX_PKG_EXTRA_CONFIGURE_ARGS"
	TERMUX_PKG_EXTRA_CONFIGURE_ARGS="$_base_args -DENABLE_CLI=OFF -DENABLE_SHARED=OFF -DEXPORT_C_API=OFF -DHIGH_BIT_DEPTH=ON"
	mkdir -p "$TERMUX_PKG_BUILDDIR/10bit_build"
	pushd "$TERMUX_PKG_BUILDDIR/10bit_build"
	termux_step_configure_cmake
	popd
	TERMUX_PKG_EXTRA_CONFIGURE_ARGS="$_base_args -DENABLE_CLI=OFF -DENABLE_SHARED=OFF -DEXPORT_C_API=OFF -DHIGH_BIT_DEPTH=ON -DMAIN12=ON"
	mkdir -p "$TERMUX_PKG_BUILDDIR/12bit_build"
	pushd "$TERMUX_PKG_BUILDDIR/12bit_build"
	termux_step_configure_cmake
	popd
	TERMUX_PKG_EXTRA_CONFIGURE_ARGS="$_base_args -DENABLE_SHARED=ON -DEXTRA_LIB=x265_main10.a;x265_main12.a -DEXTRA_LINK_FLAGS=-L$TERMUX_PKG_BUILDDIR -DLINKED_10BIT=ON -DLINKED_12BIT=ON"
	pushd "$TERMUX_PKG_BUILDDIR"
	termux_step_configure_cmake
	popd
}
termux_step_make() {
	if [ "$TERMUX_ARCH_BITS" = "32" ]; then
		cmake --build "$TERMUX_PKG_BUILDDIR"
		return
	fi
	cmake --build "$TERMUX_PKG_BUILDDIR/10bit_build"
	cmake --build "$TERMUX_PKG_BUILDDIR/12bit_build"
	ln -sfr "$TERMUX_PKG_BUILDDIR/10bit_build/libx265.a" "$TERMUX_PKG_BUILDDIR/libx265_main10.a"
	ln -sfr "$TERMUX_PKG_BUILDDIR/12bit_build/libx265.a" "$TERMUX_PKG_BUILDDIR/libx265_main12.a"
	cmake --build "$TERMUX_PKG_BUILDDIR"
}
termux_step_post_massage() {
	local _GUARD_FILE="lib/${TERMUX_PKG_NAME}.so"
	if [ ! -e "${_GUARD_FILE}" ]; then
		termux_error_exit "file ${_GUARD_FILE} not found."
	fi
}
