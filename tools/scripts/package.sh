#!/bin/sh
set -ex

STAGEDIR=/build-stage
RUSTDISTDIR=$STAGEDIR/rust-dist
ROOTFS=$STAGEDIR/rootfs
WORLDDIR=/world
TARBALL=$WORLDDIR/rootfs.tar.gz

SYSFILES=(
  /lib64/ld-*
  /usr/bin/busybox
  /usr/bin/cc
  /usr/bin/gcc
  /usr/bin/ld
  /usr/lib/*crt*
  /usr/lib/ld-*
  /usr/lib/libbfd*
  /usr/lib/libc-*
  /usr/lib/libc_*
  /usr/lib/libc.*
  /usr/lib/libcrypto*
  /usr/lib/libdl*
  /usr/lib/libgcc_s*
  /usr/lib/libm-*
  /usr/lib/libm.*
  /usr/lib/libmvec*
  /usr/lib/libncurses*
  /usr/lib/libpthread*
  /usr/lib/libreadline*
  /usr/lib/librt*
  /usr/lib/libssl*
  /usr/lib/libstdc++*
  /usr/lib/libz*
  /usr/lib/gcc
)

mkdir -p $ROOTFS
mkdir -p $ROOTFS/tmp
mkdir -p $ROOTFS/app

for sysfile in ${SYSFILES[@]}; do
  cp -vaf --parents $sysfile $ROOTFS
done

mkdir -p $RUSTDISTDIR/usr/lib
pushd $RUSTDISTDIR/usr/lib
  find ../local/lib -maxdepth 1 -exec ln -s {} \;
popd

mkdir -p $RUSTDISTDIR/usr/bin
pushd $RUSTDISTDIR/usr/bin
  find ../local/bin -maxdepth 1 -exec ln -s {} \;
popd

cp -vaf $RUSTDISTDIR/* $ROOTFS

pushd $ROOTFS
  mkdir -p bin
  /usr/bin/busybox --install -s $ROOTFS/bin
  rm -f $TARBALL
  tar -czvf $TARBALL .
popd
