TERMUX_PKG_HOMEPAGE=https://www.webmproject.org
TERMUX_PKG_DESCRIPTION="VP8 & VP9 Codec SDK"
TERMUX_PKG_LICENSE="BSD 3-Clause"
TERMUX_PKG_MAINTAINER="@termux-pacman"
TERMUX_PKG_VERSION=1.17.0
TERMUX_PKG_REVISION=2
TERMUX_PKG_SRCURL="https://github.com/webmproject/libvpx/archive/refs/tags/v${TERMUX_PKG_VERSION}.tar.gz"
TERMUX_PKG_SHA256=1020f184046187baa2985dbde38e0691f49c44088bca7a1842b0236c6081dc0a
TERMUX_PKG_DEPENDS="gcc-libs-glibc"

termux_step_configure() {
	local -a _CONFIGURE_TARGET=()
	case "$TERMUX_ARCH" in
		"aarch64") _CONFIGURE_TARGET=("--force-target=arm64-linux-gcc");;
		"arm") _CONFIGURE_TARGET=("--target=armv7-linux-gcc" "--disable-neon-asm");;
		"i686") _CONFIGURE_TARGET=("--target=x86-linux-gcc" "--disable-x86-asm" "--disable-mmx");;
		"x86_64") _CONFIGURE_TARGET=("--target=x86_64-linux-gcc" "--disable-x86-asm" "--disable-mmx");;
		*) termux_error_exit "Unsupported arch: $TERMUX_ARCH";;
	esac
	# Assembler is disabled on x86 because the glibc repositories do not ship
	# nasm/yasm; aarch64/arm NEON code is .S and is handled by gcc.
	#
	# Only the VP8/VP9 decoders are built; the encoders are not needed here.
	# Two things make this non-obvious:
	#
	# 1. --enable-vp8 / --enable-vp9 must NOT be used. Both map to
	#    enable_codec(), which does enable_feature "<codec>_encoder"
	#    "<codec>_decoder" and therefore force-enables the whole family,
	#    silently overriding an earlier --disable-vp8-encoder. Use
	#    --enable-vp8-decoder / --enable-vp9-decoder instead.
	# 2. With the encoders on, vp9/ratectrl_rtc.cc ends up in libvpx.so and
	#    logf() from it is emitted as "logf@GLIBCXX_3.4", a version that
	#    libstdc++.so.6 does not define, so every consumer failed with
	#    "undefined reference to `logf@GLIBCXX_3.4'" (this is what broke
	#    ffmpeg's libvpx probe: "libvpx enabled but no supported decoders
	#    found"). A decoder-only build links against libc only.
	"$TERMUX_PKG_SRCDIR/configure" \
		"${_CONFIGURE_TARGET[@]}" \
		--prefix="$TERMUX_PREFIX" \
		--disable-examples \
		--disable-tools \
		--disable-docs \
		--disable-unit-tests \
		--disable-realtime-only \
		--disable-vp8-encoder \
		--disable-vp9-encoder \
		--enable-vp8-decoder \
		--enable-vp9-decoder \
		--enable-pic \
		--enable-vp9-highbitdepth \
		--enable-shared \
		--disable-static \
		--enable-small \
		--as=auto \
		--extra-cflags="-fPIC"
}

termux_step_post_massage() {
	# Do not forget to bump revision of reverse dependencies and rebuild them
	# after SOVERSION is changed.
	local _SOVERSION=12
	if [ ! -e "glibc/lib/libvpx.so.${_SOVERSION}" ]; then
		termux_error_exit "libvpx.so.${_SOVERSION} not found; please check if SOVERSION has changed."
	fi
}
