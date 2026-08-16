TERMUX_PKG_HOMEPAGE=https://xemu.app/
TERMUX_PKG_DESCRIPTION="A free and open-source emulator for the original Xbox console."
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@George-Seven"
_COMMIT=956ef0b2ebe50896b7801d4f5ea621e431d9e3ae
TERMUX_PKG_VERSION=0.8.5
TERMUX_PKG_REVISION=1
TERMUX_PKG_DEPENDS="at-spi2-core, brotli, fontconfig, freetype, fribidi, gdk-pixbuf, glib, harfbuzz, libandroid-shmem, libandroid-support, libbz2, libc++, libcairo, libdecor, libepoxy, libexpat, libffi, libgraphite, libiconv, libjpeg-turbo, libpcap, libpixman, libpng, libsamplerate, libslirp, libwayland, libx11, libxau, libxcb, libxcomposite, libxcursor, libxdamage, libxdmcp, libdecor, libxext, libxfixes, libxi, libxinerama, libxkbcommon, libxrandr, libxrender, libxss, mesa, openssl, pango, pcre2, sdl2, zlib"
TERMUX_PKG_BUILD_DEPENDS="gtk3, libepoxy, libglvnd-dev, libpcap, libpixman, libsamplerate, libslirp, libtasn1, sdl2, vulkan-headers, xorgproto"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_SHA256=08be4300e513bc36f91b3c8276ff2c9572c73dd8cf98fac04fc3a8233feef1cf
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_SKIP_SRC_EXTRACT=true
TERMUX_PKG_BLACKLISTED_ARCHES="arm, i686, x86_64"
TERMUX_PKG_RM_AFTER_INSTALL="
lib/python*
"

termux_step_get_source() {
	mkdir -p "$TERMUX_PKG_SRCDIR"
	cd "$TERMUX_PKG_SRCDIR"
	git clone https://github.com/xemu-project/xemu
	cd xemu
	git checkout ${_COMMIT}
	git submodule update --init --recursive
	mv * .* ../
}

termux_step_post_get_source() {
	local s=$(find . -type f ! -path '*/.git/*' -print0 | xargs -0 sha256sum | LC_ALL=C sort | sha256sum)
	if [[ "${s}" != "${TERMUX_PKG_SHA256}  "* ]]; then
		termux_error_exit "Checksum mismatch for source files."
	fi
}

termux_step_pre_configure() {
	# Workaround for https://github.com/termux/termux-packages/issues/12261.
	if [ $TERMUX_ARCH = "aarch64" ]; then
		rm -f $TERMUX_PKG_BUILDDIR/_lib
		mkdir -p $TERMUX_PKG_BUILDDIR/_lib

		cd $TERMUX_PKG_BUILDDIR
		mkdir -p _setjmp-aarch64
		pushd _setjmp-aarch64
		mkdir -p private
		local s
		for s in $TERMUX_PKG_BUILDER_DIR/setjmp-aarch64/{setjmp.S,private-*.h}; do
			local f=$(basename ${s})
			cp ${s} ./${f/-//}
		done
		$CC $CFLAGS $CPPFLAGS -I. setjmp.S -c
		$AR cru $TERMUX_PKG_BUILDDIR/_lib/libandroid-setjmp.a setjmp.o
		popd

		LDFLAGS+=" -L$TERMUX_PKG_BUILDDIR/_lib -l:libandroid-setjmp.a"
	fi

	termux_setup_cmake
	termux_setup_ninja
	if [ "$TERMUX_ON_DEVICE_BUILD" = "true" ]; then
		termux_setup_python_pip
		pip install pyyaml
	else
		pip install --break-system-packages pyyaml
	fi
}

termux_step_configure() {
	CPPFLAGS+=" -Wno-alloca"

	CFLAGS+=" $CPPFLAGS"
	CXXFLAGS+=" $CPPFLAGS"
	LDFLAGS+=" -landroid-shmem -llog"

	# Note: using --disable-stack-protector since stack protector
	# flags already passed by build scripts but we do not want to
	# override them with what QEMU configure provides.
	if [ "$TERMUX_ON_DEVICE_BUILD" = "true" ]; then
		./configure \
			--prefix="$TERMUX_PREFIX" \
			--disable-stack-protector \
			--smbd="$TERMUX_PREFIX/bin/smbd" \
			--enable-trace-backends=nop \
			--disable-werror \
			--extra-cflags="-DXBOX=1 -Wno-error=redundant-decls ${CFLAGS}" \
			--disable-guest-agent \
			--disable-vte \
			--disable-vnc-sasl \
			--disable-xen \
			--disable-xen-pci-passthrough \
			--disable-hvf \
			--disable-whpx \
			--disable-snappy \
			--disable-lzfse \
			--disable-seccomp \
			--disable-vhost-user \
			--disable-vhost-user-blk-server \
			--target-list=i386-softmmu || { cat meson-log.txt; exit 1; }
	else
		./configure \
			--prefix="$TERMUX_PREFIX" \
			--cross-prefix="${TERMUX_HOST_PLATFORM}-" \
			--host-cc="gcc" \
			--cc="$CC" \
			--cxx="$CXX" \
			--objcc="$CC" \
			--disable-stack-protector \
			--smbd="$TERMUX_PREFIX/bin/smbd" \
			--enable-trace-backends=nop \
			--disable-werror \
			--extra-cflags="-DXBOX=1 -Wno-error=redundant-decls ${CFLAGS}" \
			--disable-guest-agent \
			--disable-vte \
			--disable-vnc-sasl \
			--disable-xen \
			--disable-xen-pci-passthrough \
			--disable-hvf \
			--disable-whpx \
			--disable-snappy \
			--disable-lzfse \
			--disable-seccomp \
			--disable-vhost-user \
			--disable-vhost-user-blk-server \
			--target-list=i386-softmmu || { cat meson-log.txt; exit 1; }
	fi
}

termux_step_make() {
	make qemu-system-i386

	mkdir -p dist
	mv build/qemu-system-i386 dist/xemu
	if test -e ./XEMU_LICENSE; then
		cp ./XEMU_LICENSE dist/LICENSE.txt
	else
		python3 ./scripts/gen-license.py > dist/LICENSE.txt
	fi

	# Utility script to convert Xbox ISO file to XISO format compatible with Xemu
	sed "s|@TERMUX_PREFIX@|${TERMUX_PREFIX}|g" "${TERMUX_PKG_BUILDER_DIR}/iso2xiso.in" > dist/iso2xiso
	chmod 755 dist/iso2xiso

	termux_download "https://archive.org/download/xemustarter/XEMU%20FILES.zip/XEMU%20FILES%2FBoot%20ROM%20Image%2Fmcpx_1.0.bin" dist/mcpx_1.0.bin e99e3a772bf5f5d262786aee895664eb96136196e37732fe66e14ae062f20335
	termux_download "https://archive.org/download/xemustarter/XEMU%20FILES.zip/XEMU%20FILES%2FBIOS%2FComplex_4627v1.03.bin" dist/4627v1.03.bin 1de4c87effe40d44f95581d204f9fa0600fbd5fe2171692316dcf97af0f4113f
	termux_download "https://github.com/xemu-project/xemu-hdd-image/releases/latest/download/xbox_hdd.qcow2.zip" dist/xbox_hdd.qcow2.zip d9f5a4c1224ff24cf9066067bda70cc8b9c874ea22b9c542eb2edbfc4621bb39
	unzip -o dist/xbox_hdd.qcow2.zip -d dist
}

termux_step_make_install() {
	install -Dm755 -t "${TERMUX_PREFIX}/bin" dist/xemu
	install -Dm755 -t "${TERMUX_PREFIX}/bin" dist/iso2xiso
	install -Dm644 -t "${TERMUX_PREFIX}/share/$TERMUX_PKG_NAME" dist/mcpx_1.0.bin
	install -Dm644 -t "${TERMUX_PREFIX}/share/$TERMUX_PKG_NAME" dist/4627v1.03.bin
	install -Dm644 -t "${TERMUX_PREFIX}/share/$TERMUX_PKG_NAME" dist/xbox_hdd.qcow2
}

termux_step_install_license() {
	install -Dm644 -t "$TERMUX_PREFIX/share/doc/$TERMUX_PKG_NAME" dist/LICENSE.txt
}

termux_step_create_debscripts() {
	# postinst to fix Xemu config
	sed "s|@TERMUX_PREFIX@|${TERMUX_PREFIX}|g" "${TERMUX_PKG_BUILDER_DIR}/postinst.in" > postinst
	chmod 755 postinst
}
