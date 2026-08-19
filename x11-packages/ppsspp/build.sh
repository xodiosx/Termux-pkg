TERMUX_PKG_HOMEPAGE=https://www.ppsspp.org/
TERMUX_PKG_DESCRIPTION="PlayStation Portable emulator"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.20.4"
TERMUX_PKG_GIT_BRANCH="v${TERMUX_PKG_VERSION}"
TERMUX_PKG_SRCURL="git+https://github.com/hrydgard/ppsspp"
TERMUX_PKG_DEPENDS="libcurl, libpng, miniupnpc, zlib, libzip, libsnappy, ffmpeg, sdl2, sdl2-ttf"
TERMUX_PKG_BUILD_DEPENDS="mesa-dev, libglvnd-dev, vulkan-headers, rapidjson, spirv-headers, spirv-tools"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DCMAKE_SYSTEM_NAME=Linux
-DUSE_SYSTEM_FFMPEG=ON
-DUSING_GLES2=ON
-DBUILD_TESTING=OFF
"
termux_step_pre_configure() {
	cd "$TERMUX_PKG_SRCDIR"
	sed -i 's/#elif defined(__ANDROID__)/#elif 0/' ppsspp_config.h
	sed -i 's/#if defined(__ANDROID__)/#if 0/g' Common/GPU/OpenGL/GLFeatures.cpp
	sed -i 's/#if defined(__ANDROID__)/#if 0/g' Common/GPU/Vulkan/VulkanLoader.h
	sed -i 's/#if defined(__ANDROID__)/#if 0/g' Common/GPU/Vulkan/VulkanLoader.cpp
	sed -i 's/#if defined(__ANDROID__)/#if 0/g' Common/GPU/Vulkan/VulkanContext.cpp
	sed -i 's/#elif defined(__ANDROID__)/#elif 1/g' Core/Instance.cpp
	sed -i 's/#if defined(__ANDROID__)/#if 0/g' Common/VR/PPSSPPVR.cpp
}
