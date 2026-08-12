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
TERMUX_PKG_BUILD_DEPENDS="pkg-config, cmake, vulkan-headers, autoconf, automake, libtool"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_configure() {
	# Allow pkg-config to find target .pc files
	export PKG_CONFIG_PATH="$TERMUX_PREFIX/lib/pkgconfig:$TERMUX_PREFIX/share/pkgconfig"
	# Pass include and library directories directly
	CFLAGS+=" -I$TERMUX_PREFIX/include"
	CPPFLAGS+=" -I$TERMUX_PREFIX/include"
	LDFLAGS+=" -L$TERMUX_PREFIX/lib -landroid-shmem"

	# Force ALSA detection to use Termux paths
	export ALSA_CFLAGS="-I$TERMUX_PREFIX/include/alsa"
	export ALSA_LIBS="-L$TERMUX_PREFIX/lib -lasound"

	./configure \
		--prefix="$TERMUX_PREFIX" \
		--host="$TERMUX_HOST_PLATFORM" \
		--disable-ffmpeg \
		--enable-vulkan \
		--enable-opengl \
		--enable-opengles \
		--enable-alsa \
		--enable-pulse \
		--enable-x11 \
		--enable-sdl2
}
