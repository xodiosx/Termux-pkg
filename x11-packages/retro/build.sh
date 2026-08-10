TERMUX_PKG_HOMEPAGE=https://www.retroarch.com/
TERMUX_PKG_DESCRIPTION="Frontend for emulators, game engines and media players"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.19.1"
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL="https://github.com/libretro/RetroArch/archive/v${TERMUX_PKG_VERSION}.tar.gz"
TERMUX_PKG_SHA256="58bf6381dbf4aa0f87a8b41725b7a0f7c231dd9ec1f9a26bd283ec4282305ca7"
TERMUX_PKG_EXCLUDED_ARCHES="arm i686"
TERMUX_PKG_DEPENDS="libandroid-shmem, libx11, libxrandr, libxext, freetype, alsa-lib, pulseaudio, openal-soft, libglvnd, ffmpeg, libsixel, qt6-qtbase, libxcb, vulkan-loader"
TERMUX_PKG_BUILD_DEPENDS="pkg-config, cmake, vulkan-headers"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--enable-vulkan
--enable-opengl
--enable-opengl_core
--enable-alsa
--enable-pulse
--enable-openal
--enable-ffmpeg
--enable-x11
--enable-qt
"

termux_step_pre_configure() {
	LDFLAGS+=" -landroid-shmem"
}
