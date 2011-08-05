#!/bin/sh

# Copyright (C) 2007 Segher Boessenkool <segher@kernel.crashing.org>
# Copyright (C) 2009-2010 Hector Martin "marcan" <hector@marcansoft.com>
# Copyright (C) 2009 Andre Heider "dhewg" <dhewg@wiibrew.org>

# Released under the terms of the GNU GPL, version 2
SCRIPTDIR=`dirname $PWD/$0`

BINUTILS_VER=2.21.1
BINUTILS_DIR="binutils-$BINUTILS_VER"
BINUTILS_TARBALL="binutils-$BINUTILS_VER.tar.bz2"
BINUTILS_URI="http://ftp.gnu.org/gnu/binutils/$BINUTILS_TARBALL"

GMP_VER=5.0.2
GMP_DIR="gmp-$GMP_VER"
GMP_TARBALL="gmp-$GMP_VER.tar.bz2"
GMP_URI="http://ftp.gnu.org/gnu/gmp/$GMP_TARBALL"

MPFR_VER=3.0.1
MPFR_DIR="mpfr-$MPFR_VER"
MPFR_TARBALL="mpfr-$MPFR_VER.tar.bz2"
MPFR_URI="http://www.mpfr.org/mpfr-$MPFR_VER/$MPFR_TARBALL"

MPC_VER=0.9
MPC_DIR="mpc-$MPC_VER"
MPC_TARBALL="mpc-$MPC_VER.tar.gz"
MPC_URI="http://www.multiprecision.org/mpc/download/$MPC_TARBALL"

GCC_VER=4.6.1
GCC_DIR="gcc-$GCC_VER"
GCC_CORE_TARBALL="gcc-core-$GCC_VER.tar.bz2"
GCC_CORE_URI="http://ftp.gnu.org/gnu/gcc/gcc-$GCC_VER/$GCC_CORE_TARBALL"

BUILDTYPE=$1

PPU_TARGET=powerpc64-linux
SPU_TARGET=spu-elf

if [ -z $MAKEOPTS ]; then
	MAKEOPTS=-j3
fi

# End of configuration section.

case `uname -s` in
	*BSD*)
		MAKE=gmake
		;;
	*)
		MAKE=make
esac

export PATH=$PS3LINUXDEV/bin:$PATH

die() {
	echo $@
	exit 1
}

cleansrc() {
	[ -e $PS3LINUXDEV/$BINUTILS_DIR ] && rm -rf $PS3LINUXDEV/$BINUTILS_DIR
	[ -e $PS3LINUXDEV/$GCC_DIR ] && rm -rf $PS3LINUXDEV/$GCC_DIR
}

cleanbuild() {
	[ -e $PS3LINUXDEV/build_binutils ] && rm -rf $PS3LINUXDEV/build_binutils
	[ -e $PS3LINUXDEV/build_gcc ] && rm -rf $PS3LINUXDEV/build_gcc
}

download() {
	DL=1
	if [ -f "$PS3LINUXDEV/$2" ]; then
		echo "Testing $2..."
		tar tf "$PS3LINUXDEV/$2" >/dev/null 2>&1 && DL=0
	fi

	if [ $DL -eq 1 ]; then
		echo "Downloading $2..."
		wget "$1" -c -O "$PS3LINUXDEV/$2" || die "Could not download $2"
	fi
}

extract() {
	echo "Extracting $1..."
	tar xf "$PS3LINUXDEV/$1" -C "$2" || die "Error unpacking $1"
}

makedirs() {
	mkdir -p $PS3LINUXDEV/build_binutils || die "Error making binutils build directory $PS3LINUXDEV/build_binutils"
	mkdir -p $PS3LINUXDEV/build_gcc || die "Error making gcc build directory $PS3LINUXDEV/build_gcc"
}

buildbinutils() {
	TARGET=$1
	(
		cd $PS3LINUXDEV/build_binutils && \
		$PS3LINUXDEV/$BINUTILS_DIR/configure --target=$TARGET \
			--prefix=$PS3LINUXDEV --disable-werror --enable-64-bit-bfd && \
		nice $MAKE $MAKEOPTS && \
		$MAKE install
	) || die "Error building binutils for target $TARGET"
}

buildgcc() {
	TARGET=$1
	(
		cd $PS3LINUXDEV/build_gcc && \
		$PS3LINUXDEV/$GCC_DIR/configure --target=$TARGET --enable-targets=all \
			--prefix=$PS3LINUXDEV \
			--enable-languages=c --without-headers \
			--disable-nls --disable-threads --disable-shared \
			--disable-libmudflap --disable-libssp --disable-libgomp \
			--disable-decimal-float \
			--enable-checking=release $EXTRA_CONFIG_OPTS && \
		nice $MAKE $MAKEOPTS all-gcc && \
		nice $MAKE $MAKEOPTS all-target-libgcc && \
		nice $MAKE $MAKEOPTS install-gcc && \
		nice $MAKE $MAKEOPTS install-target-libgcc
	) || die "Error building gcc for target $TARGET"
}

buildspu() {
	cleanbuild
	makedirs
	echo "******* Building SPU binutils"
	buildbinutils $SPU_TARGET
	echo "******* Building SPU GCC"
	buildgcc $SPU_TARGET
	echo "******* SPU toolchain built and installed"
}

buildppu() {
	cleanbuild
	makedirs
	echo "******* Building PowerPC binutils"
	buildbinutils $PPU_TARGET
	echo "******* Building PowerPC GCC"
	EXTRA_CONFIG_OPTS="--with-cpu=cell" buildgcc $PPU_TARGET
	echo "******* PowerPC toolchain built and installed"
}

if [ -z "$PS3LINUXDEV" ]; then
	die "Please set PS3LINUXDEV in your environment."
fi

case $BUILDTYPE in
	ppu|spu|both|clean)	;;
	"")
		die "Please specify build type (ppu/spu/both/clean)"
		;;
	*)
		die "Unknown build type $BUILDTYPE"
		;;
esac

if [ "$BUILDTYPE" = "clean" ]; then
	cleanbuild
	cleansrc
	exit 0
fi

download "$BINUTILS_URI" "$BINUTILS_TARBALL"
download "$GMP_URI" "$GMP_TARBALL"
download "$MPFR_URI" "$MPFR_TARBALL"
download "$MPC_URI" "$MPC_TARBALL"
download "$GCC_CORE_URI" "$GCC_CORE_TARBALL"

cleansrc

extract "$BINUTILS_TARBALL" "$PS3LINUXDEV"
patch -d $PS3LINUXDEV/$BINUTILS_DIR -u -p1 -i $SCRIPTDIR/binutils-2.21.1.patch || die "Error applying binutils patch"
extract "$GCC_CORE_TARBALL" "$PS3LINUXDEV"
extract "$GMP_TARBALL" "$PS3LINUXDEV/$GCC_DIR"
extract "$MPFR_TARBALL" "$PS3LINUXDEV/$GCC_DIR"
extract "$MPC_TARBALL" "$PS3LINUXDEV/$GCC_DIR"

# in-tree gmp, mpfr and mpc
mv "$PS3LINUXDEV/$GCC_DIR/$GMP_DIR" "$PS3LINUXDEV/$GCC_DIR/gmp" || die "Error renaming $GMP_DIR -> gmp"
mv "$PS3LINUXDEV/$GCC_DIR/$MPFR_DIR" "$PS3LINUXDEV/$GCC_DIR/mpfr" || die "Error renaming $MPFR_DIR -> mpfr"
mv "$PS3LINUXDEV/$GCC_DIR/$MPC_DIR" "$PS3LINUXDEV/$GCC_DIR/mpc" || die "Error renaming $MPC_DIR -> mpc"

case $BUILDTYPE in
	spu)		buildspu ;;
	ppu)		buildppu ;;
	both)		buildppu ; buildspu; cleanbuild; cleansrc ;;
esac

