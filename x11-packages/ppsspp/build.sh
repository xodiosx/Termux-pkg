TERMUX_PKG_HOMEPAGE=https://www.ppsspp.org/
TERMUX_PKG_DESCRIPTION="PlayStation Portable emulator"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.20.4"
TERMUX_PKG_SRCURL="https://github.com/hrydgard/ppsspp/archive/refs/tags/v${TERMUX_PKG_VERSION}.tar.gz"
TERMUX_PKG_SHA256=d09ceb1cb041319424d72ba20bd865a04208b903247dd66ec6a4a7222e1b6f3f
TERMUX_PKG_DEPENDS="sdl3, mesa-dev, glu, sdl3-ttf, fontconfig, libcurl, glew, ffmpeg, rapidjson, miniupnpc, vulkan-headers, zstd, zlib, libzip, sdl2, sdl2-ttf, libsnappy"
TERMUX_PKG_BUILD_DEPENDS="extra-cmake-modules"
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DCMAKE_SYSTEM_NAME=Linux
"
