TERMUX_PKG_HOMEPAGE="https://github.com/anholt/libepoxy"
TERMUX_PKG_DESCRIPTION="A library for handling OpenGL function pointer management (with custom ANGLE env-var patches)"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.5.10"
TERMUX_PKG_SRCURL="https://github.com/anholt/libepoxy/archive/refs/tags/${TERMUX_PKG_VERSION}.tar.gz"
# SHA256 of the GitHub archive tar.gz
TERMUX_PKG_SHA256="a7ced37f4102b745ac86d6a20a47bb146fea370160a08f17fc42bc81db199bf3"

TERMUX_PKG_DEPENDS="xorgproto"
TERMUX_PKG_BUILD_DEPENDS="pkg-config"

# Force standard X11 and EGL, drop GLX exactly as configured in your local script
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-Degl=yes
-Dglx=no
-Dx11=true
"

# Meson handles the cross-compilation automatically in Termux,
# but we need to inject the ANGLE logic right after extraction.
termux_step_post_get_source() {
	echo "Injecting ANGLE env-var auto-load logic into dispatch_common.c..."

	python3 - "$TERMUX_PKG_SRCDIR/src/dispatch_common.c" <<'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f:
    src = f.read()

old = """\
#elif defined(__ANDROID__)
#define GLX_LIB "libGLESv2.so"
#define EGL_LIB "libEGL.so"
#define GLES1_LIB "libGLESv1_CM.so"
#define GLES2_LIB "libGLESv2.so"
"""

new = """\
#elif defined(__ANDROID__)
#define GLX_LIB GLES2_LIB
static char EGL_LIB[256] = "libEGL.so";
static char GLES1_LIB[256] = "libGLESv1_CM.so";
static char GLES2_LIB[256] = "libGLESv2.so";
#include <stdio.h>
#include <stdlib.h>
EPOXY_PUBLIC void epoxy_set_library_path(const char *path) {
    snprintf(EGL_LIB, sizeof(EGL_LIB), "%s/libEGL_angle.so", path);
    snprintf(GLES1_LIB, sizeof(GLES1_LIB), "%s/libGLESv1_CM_angle.so", path);
    snprintf(GLES2_LIB, sizeof(GLES2_LIB), "%s/libGLESv2_angle.so", path);
}
__attribute__((constructor)) static void epoxy_auto_angle(void) {
    const char *p = getenv("ANGLE_LIBS_DIR");
    if (p && p[0])
        epoxy_set_library_path(p);
}
"""

if old in src:
    src = src.replace(old, new, 1)
    with open(path, 'w') as f:
        f.write(src)
    print("  -> Patched dispatch_common.c successfully.")
else:
    print("  -> ERROR: libepoxy ANGLE patch target not found in dispatch_common.c")
    sys.exit(1)
PYEOF
}
