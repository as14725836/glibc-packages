TERMUX_PKG_HOMEPAGE=https://ffmpeg.org
TERMUX_PKG_DESCRIPTION="Tools and libraries to manipulate a wide range of multimedia formats and protocols"
TERMUX_PKG_LICENSE="LGPL-2.1"
TERMUX_PKG_MAINTAINER="@termux-pacman"
TERMUX_PKG_VERSION=8.1.1
TERMUX_PKG_SRCURL=https://www.ffmpeg.org/releases/ffmpeg-${TERMUX_PKG_VERSION}.tar.xz
TERMUX_PKG_SHA256=b6863adde98898f42602017462871b5f6333e65aec803fdd7a6308639c52edf3
# Deliberately minimal build, modelled on Proton-GE's ffmpeg recipe
# (gloriouseggroll/proton-ge-custom, make/*.mk). The only consumer here is
# Wine's winedmo (dlls/winedmo), which needs libavutil, libavformat and
# libavcodec for demuxing and decoding only: no encoders, no filters and no
# command line programs.
TERMUX_PKG_DEPENDS="glibc, zlib-glibc, libbz2-glibc, liblzma-glibc, libgnutls-glibc, libdav1d-glibc"

termux_step_pre_configure() {
	cd "$TERMUX_PKG_SRCDIR"
	# The libavutil/libavcodec/libavformat major versions are part of the soname.
	# Bump TERMUX_PKG_REVISION of every reverse dependency when these change.
	declare -gA _FFMPEG_SOVER=(
		[avutil]=60
		[avcodec]=62
		[avformat]=62
	)
	local lib so_version
	for lib in util codec format; do
		so_version=$(sh ffbuild/libversion.sh av${lib} \
			libav${lib}/version.h libav${lib}/version_major.h \
			| sed -En 's/^libav'"${lib}"'_VERSION_MAJOR=([0-9]+)$/\1/p')
		if [[ ! "${so_version}" || "${_FFMPEG_SOVER[av${lib}]}" != "${so_version}" ]]; then
			termux_error_exit "SOVERSION guard check failed for libav${lib}.so: expected ${_FFMPEG_SOVER[av${lib}]}, got '${so_version}'"
		fi
	done
}

termux_step_configure() {
	cd "$TERMUX_PKG_BUILDDIR"
	local _ARCH _EXTRA_CONFIGURE_FLAGS=""
	case "$TERMUX_ARCH" in
		"aarch64")
			_ARCH="aarch64"
			_EXTRA_CONFIGURE_FLAGS="--enable-neon"
		;;
		"arm")
			_ARCH="arm"
			_EXTRA_CONFIGURE_FLAGS="--enable-neon"
		;;
		"i686")
			_ARCH="x86"
		;;
		"x86_64")
			_ARCH="x86_64"
		;;
		*) termux_error_exit "Unsupported arch: $TERMUX_ARCH";;
	esac
	# No BUILD_DEPENDS on nasm/yasm on purpose: the glibc repositories do not
	# ship such packages. x86 assembler is disabled for every architecture
	# below; on aarch64/arm the NEON code is .S and gets assembled by gcc.
	"$TERMUX_PKG_SRCDIR/configure" \
		--prefix="$TERMUX_PREFIX" \
		--arch="${_ARCH}" \
		--enable-cross-compile \
		--cc="$CC" \
		--cxx="$CXX" \
		--nm="$NM" \
		--ar="$AR" \
		--ranlib="$RANLIB" \
		--pkg-config="$PKG_CONFIG" \
		--strip="$STRIP" \
		--disable-autodetect \
		--disable-everything \
		--disable-programs \
		--disable-doc \
		--disable-debug \
		--disable-indevs \
		--disable-outdevs \
		--disable-filters \
		--disable-encoders \
		--disable-x86asm \
		--disable-static \
		--enable-shared \
		--enable-demuxers \
		--enable-decoders \
		--enable-parsers \
		--enable-bsfs \
		--enable-protocol=https \
		--enable-zlib \
		--enable-bzlib \
		--enable-lzma \
		--enable-gnutls \
		--enable-libdav1d \
		--disable-decoder=vvc \
		$_EXTRA_CONFIGURE_FLAGS
}
