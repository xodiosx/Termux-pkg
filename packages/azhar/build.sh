TERMUX_PKG_HOMEPAGE=https://azahar-emu.org/
TERMUX_PKG_DESCRIPTION="Nintendo 3DS video game console emulator"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="2125.1.3"
TERMUX_PKG_GIT_BRANCH="${TERMUX_PKG_VERSION}"
TERMUX_PKG_SRCURL="git+https://github.com/azahar-emu/azahar"
TERMUX_PKG_GIT_SUBMODULES=true
TERMUX_PKG_SHA256=a6ba40a1033bb6cac783428f3b730ff22aa419e2fb239df548afc1b535cc58cb
TERMUX_PKG_BLACKLISTED_ARCHS="arm i686"
TERMUX_PKG_DEPENDS="jack, sdl2, opengl, pipewire, qt6-qtbase, qt6-qtmultimedia, libxext, libx11, openssl, cryptopp, spirv-tools, nlohmann-json, portaudio, boost, fmt, rapidjson, zstd, libusb"
TERMUX_PKG_BUILD_DEPENDS="cmake, vulkan-headers, spirv-headers, libcpufeatures, robin-map, catch2"
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DCMAKE_INSTALL_PREFIX=${TERMUX_PREFIX}
-DENABLE_QT=ON
-DENABLE_SDL2=ON
-DENABLE_WEB_SERVICE=OFF
-DOPTION_USE_SYSTEM_ENET=OFF
-DENABLE_LTO=OFF
-DENABLE_TESTS=OFF
"

termux_step_pre_configure() {
	if [ "$TERMUX_ARCH" = "arm" ] || [ "$TERMUX_ARCH" = "i686" ]; then
		termux_error_exit "Error: Azahar (3DS emulator) only supports 64-bit architectures."
	fi
}
