TERMUX_PKG_HOMEPAGE=https://www.mesa3d.org
TERMUX_PKG_DESCRIPTION="Mesa's Freedreno Vulkan ICD (SurfaceFlinger WSI)"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_LICENSE_FILE="docs/license.rst"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="26.0.1"
TERMUX_PKG_SRCURL="https://gitlab.freedesktop.org/mesa/mesa.git"
TERMUX_PKG_GIT_BRANCH="mesa-${TERMUX_PKG_VERSION}"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DEPENDS="libc++, zlib, zstd"
TERMUX_PKG_API_LEVEL=26
TERMUX_PKG_EXCLUDED_ARCHES="i686, x86_64"
# closely based on: https://docs.mesa3d.org/android.html#building-using-the-android-ndk
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--cmake-prefix-path $TERMUX_PREFIX
-Dplatforms=android
-Dplatform-sdk-version=$TERMUX_PKG_API_LEVEL
-Dandroid-stub=true
-Dandroid-libbacktrace=disabled
-Dgallium-drivers=
-Degl=disabled
-Dvulkan-drivers=freedreno
-Dfreedreno-kmds=msm,kgsl
"

termux_step_post_get_source() {
	# Do not use meson wrap projects
	ls subprojects
	git clone --depth 1 https://gitlab.freedesktop.org/mesa/android-stub.git subprojects/android-stub
}
