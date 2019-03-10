#! /bin/bash
# With contributions from Ian McDowell: https://github.com/IMcD23

# Bail out on error
set -e

LLVM_SRCDIR=$(pwd)
OSX_BUILDDIR=$(pwd)/build_osx

#git submodule update --init --recursive

# compile for OSX (about 1h, 1GB of disk space)
if [ $CLEAN ]; then
  rm -rf $OSX_BUILDDIR
fi
if [ ! -d $OSX_BUILDDIR ]; then
  mkdir $OSX_BUILDDIR
fi

# building with -DLLVM_LINK_LLVM_DYLIB (= single big shared lib) 
# Easier to make a framework with
pushd $OSX_BUILDDIR
cmake -G Ninja \
-DLLVM_TARGETS_TO_BUILD="AArch64;X86" \
-DLLVM_LINK_LLVM_DYLIB=ON \
-DCMAKE_BUILD_TYPE=Release \
..
ninja
popd
