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

# Centralize all your custom configure flags here
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--disable-ffmpeg
--enable-vulkan
--enable-opengl
--enable-opengles
--disable-alsa
--enable-pulse
--enable-x11
--enable-sdl2
"

termux_step_configure() {
	# RetroArch uses PKG_CONF_PATH instead of the standard PKG_CONFIG variable
	export PKG_CONF_PATH="$PKG_CONFIG"

	# Explicitly include SDL2 as a fallback in case pkg-config is still ignored
	#CFLAGS+=" -I$TERMUX_PREFIX/include/SDL2"
	
	# Ensure Android shared memory library is linked
	#LDFLAGS+=" -landroid-shmem"

	# Call configure manually to avoid standard Autotools flags being injected
	#./configure \
	#	--prefix="$TERMUX_PREFIX" \
	#	$TERMUX_PKG_EXTRA_CONFIGURE_ARGS
}
