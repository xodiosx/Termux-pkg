TERMUX_PKG_HOMEPAGE=https://ppsspp.org
TERMUX_PKG_DESCRIPTION="PlayStation Portable emulator (Standalone Desktop + Separate Android Core)"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.20.4"
TERMUX_PKG_GIT_BRANCH="v${TERMUX_PKG_VERSION}"
TERMUX_PKG_SRCURL="git+https://github.com"
TERMUX_PKG_DEPENDS="sdl2, sdl2-ttf, fontconfig, libcurl, glew, libpng, rapidjson, miniupnpc, zstd, zlib, libzip, libsnappy, libcpufeatures, spirv-tools"
TERMUX_PKG_BUILD_DEPENDS="extra-cmake-modules, libglvnd-dev, vulkan-headers, spirv-headers, mesa-dev"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DCMAKE_SYSTEM_NAME=Linux
-DBUILD_TESTING=OFF
-DUSING_EGL=ON
-DUSING_FBDEV=OFF
-DUSING_GLES2=ON
-DUSING_X11_VULKAN=ON
-DUSE_WAYLAND_WSI=OFF
-DUSE_VULKAN_DISPLAY_KHR=OFF
-DUSING_QT_UI=OFF
-DMOBILE_DEVICE=OFF
-DHEADLESS=OFF
-ATLAS_TOOL=ON
-DUNITTEST=OFF
-DUSE_LIBNX=OFF
-DUSE_FFMPEG=OFF
-DUSE_DISCORD=OFF
-DUSE_MINIUPNPC=ON
-DUSE_SYSTEM_SNAPPY=ON
-DUSE_SYSTEM_FFMPEG=OFF
-DUSE_SYSTEM_FREETYPE=ON
-DUSE_SYSTEM_LIBCHDR=OFF
-DUSE_SYSTEM_LIBZIP=ON
-DUSE_SYSTEM_LIBSDL2=ON
-DUSE_SYSTEM_LIBPNG=ON
-DUSE_SYSTEM_RAPIDJSON=ON
-DUSE_SYSTEM_ZSTD=ON
-DUSE_SYSTEM_MINIUPNPC=ON
-DUSE_ASAN=OFF
-DUSE_UBSAN=OFF
-DUSE_CCACHE=OFF
-DUSE_NO_MMAP=OFF
-DFFMPEG_DIR="$TERMUX_PKG_SRCDIR/ffmpeg/android/arm64"
"

termux_step_post_extract_package() {
	cd "$TERMUX_PKG_SRCDIR"
	# 1. Pull pristine submodules (libretro-common and sub-modules) BEFORE patches touch files
	echo "Populating pristine git repositories..."
	git submodule update --init --recursive

	# 2. Run your original ashmem copy configurations
	cp -a "$TERMUX_PKG_BUILDER_DIR/Common-MemArenaAndroid.cpp" \
		"$TERMUX_PKG_SRCDIR/Common/MemArenaAndroid.cpp"

	sed -i "s|@TERMUX_PREFIX@|${TERMUX_PREFIX}|g" \
		"$TERMUX_PKG_SRCDIR/Common/MemArenaAndroid.cpp"
}

termux_step_pre_configure() {
	# PHASE 1: BUILD THE PRISTINE ANDROID RETROARCH CORE (WITHOUT DESKTOP PATCHES)
	echo "Compiling clean Android Libretro core file module..."
	
	mkdir -p "$TERMUX_PKG_SRCDIR/build_android_core"
	cd "$TERMUX_PKG_SRCDIR/build_android_core"

	# We turn OFF system ffmpeg dependencies, forcing it to find the native in-tree links.
	cmake -DCMAKE_SYSTEM_NAME=Android \
		-DLIBRETRO=ON \
		-DBUILD_TESTING=OFF \
		-DUSING_X11_VULKAN=OFF \
		-DHEADLESS=ON \
		-DUSE_SYSTEM_FFMPEG=OFF \
		-DFFMPEG_DIR="$TERMUX_PKG_SRCDIR/ffmpeg/android/arm64" \
		..

	make -j$(nproc)

	# Safely isolate the generated pristine .so file outside of the compilation layout
	if [ -f "lib/ppsspp_libretro.so" ]; then
		cp lib/ppsspp_libretro.so "$TERMUX_PKG_SRCDIR/ppsspp_libretro_android.so"
	else
		cp ppsspp_libretro.so "$TERMUX_PKG_SRCDIR/ppsspp_libretro_android.so"
	fi

	# Wipe the temporary core compiler tree directory cleanly
	rm -rf "$TERMUX_PKG_SRCDIR/build_android_core"

	echo "Proceeding with standard standalone desktop patches..."
	cd "$TERMUX_PKG_SRCDIR"
	
	cp -a "$TERMUX_PKG_BUILDER_DIR/MemArenaAndroid.cpp" \
		"$TERMUX_PKG_SRCDIR/Common/MemArenaAndroid.cpp"
		
	sed -i "s|@TERMUX_PREFIX@|${TERMUX_PREFIX}|g" \
		"$TERMUX_PKG_SRCDIR/Common/MemArenaAndroid.cpp"
		
	sed -i 's/Arm64EmitterTest();/\/\/ Arm64EmitterTest();/' UI/NativeApp.cpp
	sed -i 's/ArmEmitterTest();/\/\/ ArmEmitterTest();/' UI/NativeApp.cpp
	
	find \
		"$TERMUX_PKG_SRCDIR"/Common/GPU \
		"$TERMUX_PKG_SRCDIR"/Common/Log.h \
		"$TERMUX_PKG_SRCDIR"/Common/MsgHandler.h \
		"$TERMUX_PKG_SRCDIR"/ext/naett \
		"$TERMUX_PKG_SRCDIR"/ppsspp_config.h \
		-type f -print0 | xargs -0 sed -i \
		-e 's/\([^A-Za-z0-9_]__ANDROID\)\(__[^A-Za-z0-9_]\)/\1__DISABLING_THIS_BECAUSE_IT_IS_FOR_BUILDING_AN_APK\2/g' \
		-e 's/\([^A-Za-z0-9_]__ANDROID\)__$/\1_DISABLING_THIS_BECAUSE_IT_IS_FOR_BUILDING_AN_APK__/g'
}

termux_step_post_make_install() {
	# 1. Handle original symlink installation for standalone
	cd $TERMUX_PREFIX/bin
	ln -sf PPSSPPSDL "$TERMUX_PREFIX/bin/ppsspp"

	# 2. Inject the pristine saved Android core directly into the packaging layout
	echo "Injecting clean Libretro core into final package directory..."
	mkdir -p "$TERMUX_PREFIX/lib/libretro"
	cp "$TERMUX_PKG_SRCDIR/ppsspp_libretro_android.so" "$TERMUX_PREFIX/lib/libretro/ppsspp_libretro.so"
}
