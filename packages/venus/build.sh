TERMUX_PKG_HOMEPAGE=https://virgil3d.github.io/
TERMUX_PKG_DESCRIPTION="A virtual 3D GPU for use inside qemu virtual machines"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.2.0"
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL=https://gitlab.freedesktop.org/virgl/virglrenderer/-/archive/virglrenderer-${TERMUX_PKG_VERSION}/virglrenderer-virglrenderer-${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=b181b668afae817953c84635fac2dc4c2e5786c710b7d225ae215d15674a15c7
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DEPENDS="libdrm, libepoxy, libglvnd, libx11, mesa"
TERMUX_PKG_BUILD_DEPENDS="xorgproto"

# Configure for static outputs
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="-Dplatforms=egl,glx -Ddefault_library=static"

termux_step_pre_configure() {
	# Fix Clang offsetof warning turning into an error
	CPPFLAGS+=" -Wno-error=gnu-offsetof-extensions"

	# Append the static flag to the linker
	LDFLAGS+=" -static"

	find "$TERMUX_PKG_SRCDIR" -name "anon_file.c" -exec sed -i '1s/^/#include <sys\/syscall.h>\n#include <unistd.h>\n/' {} +
	
	find "$TERMUX_PKG_SRCDIR" -name "anon_file.c" -exec sed -i 's/memfd_create(/syscall(SYS_memfd_create, /g' {} +

	if [[ $TERMUX_ARCH != "arm" ]]; then
		TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -Dvenus=true"
	fi
}
