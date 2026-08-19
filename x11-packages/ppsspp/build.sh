TERMUX_PKG_HOMEPAGE=https://www.ppsspp.org/
TERMUX_PKG_DESCRIPTION="PlayStation Portable emulator"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.20.4"
TERMUX_PKG_GIT_BRANCH="v${TERMUX_PKG_VERSION}"
TERMUX_PKG_EXCLUDED_ARCHES="arm i686 x86_64"
TERMUX_PKG_SRCURL="git+https://github.com/hrydgard/ppsspp"
TERMUX_PKG_DEPENDS="libcurl, libpng, miniupnpc, zlib, libzip, libsnappy, ffmpeg, sdl2, sdl2-ttf"
TERMUX_PKG_BUILD_DEPENDS="mesa-dev, libglvnd-dev, vulkan-headers, rapidjson, spirv-headers, spirv-tools"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DCMAKE_SYSTEM_NAME=Linux
-DCMAKE_SYSTEM_PROCESSOR=aarch64
-DUSE_SYSTEM_FFMPEG=ON
-DUSING_GLES2=OFF
-DBUILD_TESTING=OFF
"
termux_step_pre_configure() {
	cd "$TERMUX_PKG_SRCDIR"
	sed -i '120s/.*/#elif 0/' ppsspp_config.h
	sed -i '403s/.*/#if 0/' Common/GPU/OpenGL/GLFeatures.cpp
	sed -i '456s/.*/#if 0/' Common/GPU/OpenGL/GLFeatures.cpp
	sed -i '194s/.*/#if 0/' Common/GPU/Vulkan/VulkanLoader.h
	sed -i '192s/.*/#if 0/' Common/GPU/Vulkan/VulkanLoader.cpp
	sed -i '350s/.*/#if 1/' Common/GPU/Vulkan/VulkanLoader.cpp
	sed -i '503s/.*/#elif 0/' Common/GPU/Vulkan/VulkanLoader.cpp
	sed -i '752s/.*/#elif 0/' Common/GPU/Vulkan/VulkanLoader.cpp
	sed -i '155s/.*/#elif 0/' Common/GPU/Vulkan/VulkanContext.cpp
	sed -i '1063s/.*/#if 0/' Common/GPU/Vulkan/VulkanContext.cpp
	sed -i '145s/.*/#elif 1/' Core/Instance.cpp
	sed -i '182s/.*/#elif 1/' Core/Instance.cpp
}
