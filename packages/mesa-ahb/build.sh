TERMUX_PKG_HOMEPAGE=https://www.mesa3d.org
TERMUX_PKG_DESCRIPTION="Mesa's Freedreno Vulkan ICD (SurfaceFlinger WSI)"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_LICENSE_FILE="docs/license.rst"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="26.0.1"
TERMUX_PKG_SRCURL="https://archive.mesa3d.org/mesa-${TERMUX_PKG_VERSION}.tar.xz"
TERMUX_PKG_SHA256=bb5104f9f9a46c9b5175c24e601e0ef1ab44ce2d0fdbe81548b59adc8b385dcc
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
-Dfreedreno-kmds=kgsl
"

termux_step_post_get_source() {
	# Do not use meson wrap projects
	rm -rf subprojects
sed -i 's/ (%s)//g' src/freedreno/vulkan/tu_device.cc || true
    sed -i 's/ (%s)//g' src/freedreno/vulkan/tu_device.c || true

    sed -i '/a7xx_gen1 = GPUProps(/a \        has_early_preamble = False,' \
        src/freedreno/common/freedreno_devices.py || true

    sed -i 's/typedef const native_handle_t\* buffer_handle_t;/typedef void\* buffer_handle_t;/g' \
        include/android_stub/cutils/native_handle.h || true

    sed -i 's/, hnd->handle/, (void \*)hnd->handle/g' \
        src/util/u_gralloc/u_gralloc_fallback.c || true

    sed -i 's/native_buffer->handle->/((const native_handle_t \*)native_buffer->handle)->/g' \
        src/vulkan/runtime/vk_android.c || true

    sed -i 's/anb->handle->/((const native_handle_t \*)anb->handle)->/g' \
        src/vulkan/runtime/vk_android.c || true

    echo '#define TUGEN8_DRV_VERSION ""' > src/freedreno/vulkan/tu_version.h

}
