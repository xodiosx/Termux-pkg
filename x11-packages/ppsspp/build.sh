TERMUX_PKG_HOMEPAGE=https://www.ppsspp.org/
TERMUX_PKG_DESCRIPTION="PlayStation Portable emulator"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.20.4"
TERMUX_PKG_GIT_BRANCH="v${TERMUX_PKG_VERSION}"

TERMUX_PKG_SRCURL="git+https://github.com/hrydgard/ppsspp"
TERMUX_PKG_DEPENDS="libcurl, libpng, miniupnpc, zlib, libzip, glew, libsnappy, ffmpeg, libcpufeatures, rapidjson, sdl2, sdl2-ttf, fontconfig"
TERMUX_PKG_BUILD_DEPENDS="mesa-dev, libglvnd-dev, vulkan-headers, rapidjson, spirv-headers, spirv-tools"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DCMAKE_SYSTEM_NAME=Linux
-DUSE_SYSTEM_FFMPEG=ON
-DUSE_SYSTEM_LIBZIP=ON
-DUSE_SYSTEM_SNAPPY=ON
-DUSE_WAYLAND_WSI=OFF
-DUSING_EGL=ON
-DUSING_FBDEV=OFF
-DUSING_X11_VULKAN=ON
-DUSING_GLES2=ON
-DUSE_VULKAN_DISPLAY_KHR=OFF
-DLIBRETRO=OFF
-DUSE_SYSTEM_FREETYPE=ON
-DUSE_SYSTEM_LIBCHDR=OFF
-DUSE_SYSTEM_LIBZIP=ON
-DUSING_QT_UI=OFF
-DHEADLESS=OFF
-DUSE_SYSTEM_LIBPNG=ON
-DUSE_SYSTEM_RAPIDJSON=ON
-DUSE_SYSTEM_ZSTD=ON
-DUSE_SYSTEM_MINIUPNPC=ON
-DUSE_ASAN=OFF
-DUSE_UBSAN=OFF
-DUSE_CCACHE=OFF
-DUSE_NO_MMAP=OFF
-DBUILD_TESTING=OFF
-DCMAKE_PREFIX_PATH=${TERMUX_PREFIX}
-DSDL2_INCLUDE_DIR=${TERMUX_PREFIX}/include/SDL2
-DSDL2_LIBRARY=${TERMUX_PREFIX}/lib/libSDL2.so
-DSDL2_TTF_INCLUDE_DIR=${TERMUX_PREFIX}/include/SDL2
-DSDL2_TTF_LIBRARY=${TERMUX_PREFIX}/lib/libSDL2_ttf.so
"

termux_step_pre_configure() {
	cd "$TERMUX_PKG_SRCDIR"
	sed -i 's/Arm64EmitterTest();/\/\/ Arm64EmitterTest();/' UI/NativeApp.cpp
	sed -i 's/ArmEmitterTest();/\/\/ ArmEmitterTest();/' UI/NativeApp.cpp
	# Patch cpu_features so empty CMAKE_SYSTEM_PROCESSOR is inferred from compiler
	sed -i '/set(PROCESSOR_IS_LOONGARCH FALSE)/a\
if(CMAKE_SYSTEM_PROCESSOR STREQUAL "")\
	if(CMAKE_C_COMPILER_TARGET MATCHES "aarch64|arm64")\
		set(CMAKE_SYSTEM_PROCESSOR "aarch64")\
	elseif(CMAKE_C_COMPILER_TARGET MATCHES "armv7|arm-linux-androideabi")\
		set(CMAKE_SYSTEM_PROCESSOR "arm")\
	elseif(CMAKE_C_COMPILER_TARGET MATCHES "x86_64|amd64")\
		set(CMAKE_SYSTEM_PROCESSOR "x86_64")\
	elseif(CMAKE_C_COMPILER_TARGET MATCHES "i686|i586|i486|i386")\
		set(CMAKE_SYSTEM_PROCESSOR "i686")\
	elseif(CMAKE_C_COMPILER_TARGET MATCHES "riscv64|riscv")\
		set(CMAKE_SYSTEM_PROCESSOR "riscv64")\
	elseif(CMAKE_C_COMPILER_TARGET MATCHES "loongarch64|loongarch")\
		set(CMAKE_SYSTEM_PROCESSOR "loongarch64")\
	elseif(CMAKE_C_COMPILER MATCHES "aarch64|arm64")\
		set(CMAKE_SYSTEM_PROCESSOR "aarch64")\
	elseif(CMAKE_C_COMPILER MATCHES "armv7|arm-linux-androideabi")\
		set(CMAKE_SYSTEM_PROCESSOR "arm")\
	elseif(CMAKE_C_COMPILER MATCHES "x86_64|amd64")\
		set(CMAKE_SYSTEM_PROCESSOR "x86_64")\
	elseif(CMAKE_C_COMPILER MATCHES "i686|i586|i486|i386")\
		set(CMAKE_SYSTEM_PROCESSOR "i686")\
	elseif(CMAKE_C_COMPILER MATCHES "riscv64|riscv")\
		set(CMAKE_SYSTEM_PROCESSOR "riscv64")\
	elseif(CMAKE_C_COMPILER MATCHES "loongarch64|loongarch")\
		set(CMAKE_SYSTEM_PROCESSOR "loongarch64")\
	else()\
		message(FATAL_ERROR "Cannot infer CMAKE_SYSTEM_PROCESSOR from compiler")\
	endif()\
endif()' \
		ext/cmake/cpu_features/CMakeLists.txt
	#sed -i '194s/.*/#if 0/' Common/GPU/Vulkan/VulkanLoader.h
	#sed -i '192s/.*/#if 0/' Common/GPU/Vulkan/VulkanLoader.cpp
	#sed -i '350s/.*/#if 1/' Common/GPU/Vulkan/VulkanLoader.cpp
	#sed -i '503s/.*/#elif 0/' Common/GPU/Vulkan/VulkanLoader.cpp
	#sed -i '752s/.*/#elif 0/' Common/GPU/Vulkan/VulkanLoader.cpp
	#sed -i '155s/.*/#elif 0/' Common/GPU/Vulkan/VulkanContext.cpp
	#sed -i '1063s/.*/#if 0/' Common/GPU/Vulkan/VulkanContext.cpp
	#sed -i '145s/.*/#elif 1/' Core/Instance.cpp
	#sed -i '182s/.*/#elif 1/' Core/Instance.cpp
		find \
		"$TERMUX_PKG_SRCDIR"/Common/GPU \
		"$TERMUX_PKG_SRCDIR"/Common/Log.h \
		"$TERMUX_PKG_SRCDIR"/Common/MsgHandler.h \
		"$TERMUX_PKG_SRCDIR"/UI \
		"$TERMUX_PKG_SRCDIR"/ext/naett \
		"$TERMUX_PKG_SRCDIR"/ppsspp_config.h \
		-type f -print0 | xargs -0 sed -i \
		-e 's/\([^A-Za-z0-9_]__ANDROID\)\(__[^A-Za-z0-9_]\)/\1__DISABLING_THIS_BECAUSE_IT_IS_FOR_BUILDING_AN_APK\2/g' \
		-e 's/\([^A-Za-z0-9_]__ANDROID\)__$/\1_DISABLING_THIS_BECAUSE_IT_IS_FOR_BUILDING_AN_APK__/g'
}

termux_step_post_make_install() {
	# Create a convenience symlink: ppsspp -> PPSSPPSDL
	cd $TERMUX_PREFIX/bin
	ln -sf PPSSPPSDL "$TERMUX_PREFIX/bin/ppsspp"
}
