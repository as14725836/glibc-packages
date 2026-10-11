TERMUX_PKG_HOMEPAGE=https://github.com/as14725836/win-fg
TERMUX_PKG_DESCRIPTION="Win-FG Native — clean-room frame generation for Vulkan (implicit layer for Winlator/Wine)"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux-pacman"
TERMUX_PKG_VERSION="0.3.0"
TERMUX_PKG_SRCURL=https://github.com/as14725836/win-fg/archive/ecf6446ae2074ff6eb40d658df12c01a3c37022c.tar.gz
TERMUX_PKG_SHA256=7c6ed7ca4f943db52a5b363afb9603698abc62d649be33c520585e23e850830a
TERMUX_PKG_DEPENDS="gcc-libs-glibc"
TERMUX_PKG_BUILD_DEPENDS="vulkan-headers-glibc, glslang-glibc"
# The layer manifest declares library_arch=64 (see manifest/VkLayer_win_framegen.json),
# so only 64-bit targets are meaningful; 32-bit builds would be ignored by the loader.
TERMUX_PKG_EXCLUDED_ARCHES="arm, i686"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DVULKAN_INCLUDE=${TERMUX_PREFIX}/include
-DWINFG_GIT_DESCRIBE=v${TERMUX_PKG_VERSION}-glibc
"

# win-fg ships no CMake install() rules, and its shaders must be compiled to
# SPIR-V and embedded before configure. Handle both here.
termux_step_pre_configure() {
	# 1) Compile the .comp shaders to Turnip-safe SPIR-V (Vulkan 1.1).
	#    Needs glslangValidator from the glslang-glibc build dep.
	cd "${TERMUX_PKG_SRCDIR}"
	sh tools/build_shaders.sh

	# 2) Embed the SPIR-V into src/embedded_shaders.hpp.
	python3 tools/embed_spv.py
}

termux_step_make_install() {
	# The default cmake install (ninja install) installs nothing because
	# win-fg has no install() rules, so install the layer by hand.
	install -Dm755 "${TERMUX_PKG_BUILDDIR}/libwin_fg.so" \
		"${TERMUX_PREFIX}/lib/libwin_fg.so"

	# Vulkan implicit layer manifest: loader searches
	#   <FALLBACK_DATA_DIRS>/vulkan/implicit_layer.d/
	# and vulkan-icd-loader here sets FALLBACK_DATA_DIRS to
	#   $TERMUX_PREFIX/local/share:$TERMUX_PREFIX/share
	install -Dm644 "${TERMUX_PKG_SRCDIR}/manifest/VkLayer_win_framegen.json" \
		"${TERMUX_PREFIX}/share/vulkan/implicit_layer.d/VkLayer_win_framegen.json"

	# Point the manifest at the absolute path of the installed .so (the
	# upstream json uses the relative "./libwin_fg.so").
	sed -i "s|\"library_path\": \"./libwin_fg.so\"|\"library_path\": \"${TERMUX_PREFIX}/lib/libwin_fg.so\"|" \
		"${TERMUX_PREFIX}/share/vulkan/implicit_layer.d/VkLayer_win_framegen.json"
}
