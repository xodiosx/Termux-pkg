TERMUX_PKG_HOMEPAGE=https://www.retroarch.com/
TERMUX_PKG_DESCRIPTION="Frontend for emulators, game engines and media players"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.19.1"
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL="https://github.com/libretro/RetroArch/archive/v${TERMUX_PKG_VERSION}.tar.gz"
TERMUX_PKG_SHA256="504a3a8a6e5861eb43a61be8339f61183e7ea940c1ff68ac2a2f57d35c67f8ff"
TERMUX_PKG_EXCLUDED_ARCHES="arm i686 x86_64"
TERMUX_PKG_DEPENDS="libandroid-shmem, fontconfig, libzip, libx11, libxrandr, libxext, freetype, alsa-lib, pulseaudio, sdl2, sdl2-ttf, libglvnd, ffmpeg, libsixel, zlib, libxcb, vulkan-loader"
TERMUX_PKG_BUILD_DEPENDS="pkg-config, cmake, vulkan-headers, autoconf, automake, mesa-dev, libtool"
TERMUX_PKG_BUILD_IN_SRC=true

TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--disable-ffmpeg
--enable-vulkan
--disable-opengl
--enable-opengles
--enable-egl
--enable-alsa
--enable-pulse
--enable-x11
--enable-sdl2
--disable-wayland
"

termux_step_pre_configure() {
	# Ensure pkg-config is found
	export PKG_CONFIG="$TERMUX_PREFIX/bin/pkg-config"
	export PKG_CONFIG_PATH="$TERMUX_PREFIX/lib/pkgconfig:$TERMUX_PREFIX/share/pkgconfig"

	# Compiler / linker flags for Termux
	CFLAGS+=" -I$TERMUX_PREFIX/include"
	CPPFLAGS+=" -I$TERMUX_PREFIX/include"
	LDFLAGS+=" -L$TERMUX_PREFIX/lib -landroid-shmem"

	# Help ALSA detection (overrides hardcoded paths)
	export ALSA_CFLAGS="-I$TERMUX_PREFIX/include/alsa"
	export ALSA_LIBS="-L$TERMUX_PREFIX/lib -lasound"

}

termux_step_configure() {
	# Run configure manually to avoid the unwanted --disable-dependency-tracking
	./configure \
		--prefix="$TERMUX_PREFIX" \
		--host="$TERMUX_HOST_PLATFORM" \
		$TERMUX_PKG_EXTRA_CONFIGURE_ARGS
}
