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
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="-Dplatforms=egl,glx -Ddefault_library=static"

termux_step_pre_configure() {
	CPPFLAGS+=" -Wno-error=gnu-offsetof-extensions"
	LDFLAGS+=" -static"

	local f
	for f in $(find "$TERMUX_PKG_SRCDIR" -type f -name "*.c"); do
		if grep -q "memfd_create" "$f"; then
			sed -i 's/\bmemfd_create\s*(/termux_memfd_create(/g' "$f"
			sed -i '1s/^/#include <sys\/syscall.h>\n#include <unistd.h>\nstatic inline int termux_memfd_create(const char *n, unsigned int f) { return syscall(SYS_memfd_create, n, f); }\n/' "$f"
		fi
		if grep -q "timespec_get" "$f"; then
			sed -i 's/\btimespec_get\s*(/termux_timespec_get(/g' "$f"
			sed -i '1s/^/#include <time.h>\n#ifndef TIME_UTC\n#define TIME_UTC 1\n#endif\nstatic inline int termux_timespec_get(struct timespec *ts, int b) { return clock_gettime(0, ts) == 0 ? b : 0; }\n/' "$f"
		fi
	done

	if [[ $TERMUX_ARCH != "arm" ]]; then
		TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -Dvenus=true"
	fi
}
