#!/bin/sh
set -ex

# Based on:
# https://github.com/rust-lang/rust/blob/4b79add08653d89f08e5a5c94c2132515a1aa30f/src/doc/trpl/advanced-linking.md

STAGEDIR=/build-stage
SOURCEDIR=$STAGEDIR/sources
MUSLVER="musl-1.1.11"
MUSLDIST=$STAGEDIR/musl-dist
UNWINDBUILDDIR=$SOURCEDIR/llvm/projects/libunwind/build
RUSTBUILDDIR=$SOURCEDIR/rust
CARGOBUILDDIR=$SOURCEDIR/cargo
RUSTDISTDIR=$STAGEDIR/rust-dist

mkdir -p $STAGEDIR/bin
pushd $STAGEDIR/bin
  ln -s $(which python2) python
  PATH=$PATH:$STAGEDIR/bin
popd

mkdir -p $SOURCEDIR
pushd $SOURCEDIR
  svn co http://llvm.org/svn/llvm-project/llvm/trunk llvm
  wget http://www.musl-libc.org/releases/$MUSLVER.tar.gz
  tar xf $MUSLVER.tar.gz
  git clone --single-branch --branch master https://github.com/rust-lang/rust.git
  git clone --single-branch --branch master https://github.com/rust-lang/cargo.git
  pushd $CARGOBUILDDIR
    git submodule update --init
  popd
popd

pushd $SOURCEDIR/llvm/projects
  svn co http://llvm.org/svn/llvm-project/libcxxabi/trunk libcxxabi
  svn co http://llvm.org/svn/llvm-project/libunwind/trunk libunwind
  sed -i 's#^\(include_directories\).*$#\0\n\1(../libcxxabi/include)#' libunwind/CMakeLists.txt
popd

pushd $SOURCEDIR/$MUSLVER
  ./configure --disable-shared --prefix=$MUSLDIST
  make -j4
  make install
popd

mkdir -p $UNWINDBUILDDIR
pushd $UNWINDBUILDDIR
  cmake \
    -DLLVM_PATH=../../.. \
    -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
    -DLIBUNWIND_ENABLE_SHARED=0 ..
  make -j4
  cp lib/libunwind.a $MUSLDIST/lib/
popd

pushd $RUSTBUILDDIR
  ./configure --target=x86_64-unknown-linux-musl --musl-root=$MUSLDIST
  make -j4
  make install DESTDIR=$RUSTDISTDIR
popd

pushd $CARGOBUILDDIR
  ./configure \
    --target=x86_64-unknown-linux-gnu \
    --local-rust-root=$RUSTDISTDIR/usr/local
  make
  make install DESTDIR=$RUSTDISTDIR
popd

rm -rf $SOURCEDIR $MUSLDIST
