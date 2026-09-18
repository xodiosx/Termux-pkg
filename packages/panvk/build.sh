TERMUX_PKG_HOMEPAGE=https://www.mesa3d.org
TERMUX_PKG_DESCRIPTION="Mesa with PanVK (kbase/JM) for Mali-G57 — Termux native"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_LICENSE_FILE="docs/license.rst"
TERMUX_PKG_MAINTAINER="@yourname"
TERMUX_PKG_VERSION="26.0.6"
TERMUX_PKG_REVISION=1

TERMUX_PKG_SRCURL=git+https://github.com/xodiosx/mesa-panvk-g57
TERMUX_PKG_GIT_BRANCH=main
TERMUX_PKG_AUTO_UPDATE=false

# Meson buildtype goes through this framework variable, NOT -Dbuildtype.
TERMUX_PKG_MESON_BUILDTYPE=debugoptimized

TERMUX_PKG_DEPENDS="libandroid-shmem, libc++, libdrm, libllvm (<< $TERMUX_LLVM_NEXT_MAJOR_VERSION), libx11, libxext, libxfixes, libxshmfence, libxxf86vm, vulkan-loader, zlib, zstd"
TERMUX_PKG_SUGGESTS="mesa-dev"
TERMUX_PKG_BUILD_DEPENDS="libclc, libxrandr, llvm, llvm-tools, mlir, spirv-tools, xorgproto"

TERMUX_PKG_BREAKS="osmesa, osmesa-demos"
TERMUX_PKG_CONFLICTS="libmesa, ndk-sysroot (<= 25b), osmesa"
TERMUX_PKG_REPLACES="libmesa, osmesa"

TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--cmake-prefix-path $TERMUX_PREFIX
-Dplatforms=x11
-Dglx=disabled
-Degl=disabled
-Dopengl=false
-Dgles1=disabled
-Dgles2=disabled
-Dgbm=disabled
-Dglvnd=disabled
-Dllvm=enabled
-Dshared-llvm=enabled
-Dxmlconfig=disabled
-Dgallium-drivers=
-Dvulkan-drivers=panfrost
-Dpanfrost-kmds=kbase,panthor
-Dpanvk-use-kbase=true
-Dpanfrost-rust=false
-Dbuild-tests=false
-Dlibunwind=disabled
-Dvalgrind=disabled
-Dperfetto=false
-Dandroid-libbacktrace=disabled
"

termux_step_post_get_source() {
	# Do not use meson wrap projects
	rm -rf subprojects

	# ------------------------------------------------------------------
	# Fix #1 — vtn_bindgen2 (src/compiler/spirv/meson.build:83)
	#
	# vtn_bindgen2 is `native : not can_run_host_binaries()` (true in
	# cross), but its `dependencies : [idep_vtn, …]` pulls in
	# `link_with : libvtn`, and libvtn is a host target. Meson refuses.
	# vtn_bindgen2.c only reads headers — no libvtn symbols — so:
	#   (a) list the generated headers as sources so they build first,
	#   (b) drop idep_vtn from dependencies.
	# ------------------------------------------------------------------
	sed -i \
		-e "s|\['vtn_bindgen2.c'\],|['vtn_bindgen2.c', vtn_generator_ids_h, spirv_info_h],|" \
		-e "s|dependencies : \[idep_vtn, idep_mesautil, idep_nir\],|dependencies : [],|" \
		src/compiler/spirv/meson.build

	echo "=== vtn_bindgen2 block after sed ==="
	sed -n '/prog_vtn_bindgen2 = executable/,/^   )/p' src/compiler/spirv/meson.build

	# ------------------------------------------------------------------
	# Fix #2 — remove with_panfrost_vk from with_driver_using_cl
	# (meson.build, top level)
	#
	# The fork wrongly lists PanVK in the "drivers that use CLC" array.
	# CLC is the OpenCL C compiler; PanVK has nothing to do with it.
	# Removing that token makes with_clc=false for a PanVK-only build,
	# so src/compiler/clc is never entered.
	# ------------------------------------------------------------------
	sed -i \
		"s|with_gallium_panfrost, with_panfrost_vk,|with_gallium_panfrost,|" \
		meson.build

	echo "=== with_driver_using_cl after sed ==="
	sed -n '/with_driver_using_cl = \[/,/\].contains(true)/p' meson.build

	# ------------------------------------------------------------------
	# Fix #3 — guard subdir('cl') in src/poly/meson.build
	#
	# With with_clc=false, prog_mesa_clc is never defined. But
	# src/poly/meson.build enters subdir('cl') unconditionally, and
	# src/poly/cl/meson.build references prog_mesa_clc at line 14.
	# Wrapping that subdir in `if with_clc` skips it entirely when CLC
	# is not being built.
	# ------------------------------------------------------------------
	sed -i "s|^subdir('cl')|if with_clc\n  subdir('cl')\nendif|" src/poly/meson.build

	if grep -q "^if with_clc" src/poly/meson.build; then
		echo "OK: subdir('cl') guarded with with_clc"
	else
		echo "WARN: sed for src/poly/meson.build did not match — check manually"
	fi

	echo "=== src/poly/meson.build after sed ==="
	cat src/poly/meson.build
}

termux_step_pre_configure() {
		# Skip the android-detection patch — the fork already has it.
		for p in "$TERMUX_SCRIPTDIR"/packages/mesa/*.patch; do
			[ -f "$p" ] || continue
			case "$(basename "$p")" in
				0000-disable-android-detection.patch)
					echo "Skipping $(basename "$p") (already applied in fork)"
					continue
					;;
			esac
			echo "Applying $(basename "${p}")"
			sed "s|@TERMUX_PREFIX@|${TERMUX_PREFIX}|g" "${p}" \
				| patch --silent -p1 -d "$TERMUX_PKG_SRCDIR" \
				|| echo "  ⚠ $(basename "${p}") did not apply — skipped"
		done

	termux_setup_cmake

	# PanVK kbase/JM does not need Rust/bindgen, so no
	# termux_setup_rust / cargo install bindgen-cli here.

	CPPFLAGS+=" -D__USE_GNU"
	LDFLAGS+=" -landroid-shmem"

	_WRAPPER_BIN=$TERMUX_PKG_BUILDDIR/_wrapper/bin
	mkdir -p "$_WRAPPER_BIN"
	if [ "$TERMUX_ON_DEVICE_BUILD" = "false" ]; then
		# cmake-wrapper.in lives in the mesa package dir, not panvk/.
		local cmake_wrapper="$TERMUX_SCRIPTDIR/packages/mesa/cmake-wrapper.in"
		if [ -f "$cmake_wrapper" ]; then
			sed 's|@CMAKE@|'"$(command -v cmake)"'|g' "$cmake_wrapper" \
				> "$_WRAPPER_BIN/cmake"
			chmod 0700 "$_WRAPPER_BIN/cmake"
		fi
		termux_setup_wayland_cross_pkg_config_wrapper
	fi
	export LLVM_CONFIG="${TERMUX_PREFIX}/bin/llvm-config"
	export PATH="$_WRAPPER_BIN:${PATH}"
}

termux_step_post_configure() {
	rm -f "$TERMUX_PKG_BUILDDIR/_wrapper/bin/cmake"
}

termux_step_post_make_install() {
	# Avoid hard links in $PREFIX/lib/dri (same trick as upstream)
	local f1 f2 s1 s2
	for f1 in "$TERMUX_PREFIX"/lib/dri/*; do
		[ -f "$f1" ] || continue
		for f2 in "$TERMUX_PREFIX"/lib/dri/*; do
			if [ -f "$f2" ] && [ "$f1" != "$f2" ]; then
				s1=$(stat -c "%i" "$f1")
				s2=$(stat -c "%i" "$f2")
				if [ "$s1" = "$s2" ]; then
					ln -sfr "$f1" "$f2"
				fi
			fi
		done
	done

	# Symlinks for the Mesa EGL/GLX/CL entry points
	ln -sf libEGL_mesa.so "$TERMUX_PREFIX/lib/libEGL_mesa.so.0"
	ln -sf libGLX_mesa.so "$TERMUX_PREFIX/lib/libGLX_mesa.so.0"
	ln -sf libRusticlOpenCL.so "$TERMUX_PREFIX/lib/libRusticlOpenCL.so.1"

	unset LLVM_CONFIG
}
