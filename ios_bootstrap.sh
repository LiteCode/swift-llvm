#! /bin/bash
# With contributions from Ian McDowell: https://github.com/IMcD23

# Bail out on error
set -e

LLVM_SRCDIR=$(pwd)
OSX_BUILDDIR=$(pwd)/build_osx
IOS_BUILDDIR=$(pwd)/build_ios
FFI_SRCDIR=$(pwd)/libffi-3.2.1/

LIBFFI_SRC=https://www.mirrorservice.org/sites/sourceware.org/pub/libffi/libffi-3.2.1.tar.gz

IOS_SDKROOT=$(xcrun --sdk iphoneos --show-sdk-path)


if [ $CLEAN ]; then
  rm -rf $IOS_BUILDDIR
fi
if [ ! -d $IOS_BUILDDIR ]; then
  mkdir $IOS_BUILDDIR
fi

# get libffi:
if [ ! -d $FFI_SRCDIR ]; then 
	echo "Downloading libffi-3.2.1" 
	curl $LIBFFI_SRC | tar xz 
	echo "Applying patch to libffi-3.2.1:"
	pushd $FFI_SRCDIR
	# patch -p 1 < ../libffi-3.2.1_patch
	echo "Compiling libffi:"
	xcodebuild -project libffi.xcodeproj -target libffi-iOS -sdk iphoneos -arch arm64 -configuration Debug -quiet
	popd
fi

pushd $IOS_BUILDDIR
cmake -G Ninja \
-DLLVM_LINK_LLVM_DYLIB=ON \
-DLLVM_TARGET_ARCH=AArch64 \
-DLLVM_TARGETS_TO_BUILD="AArch64" \
-DLLVM_DEFAULT_TARGET_TRIPLE=arm64-apple-darwin17.5.0 \
-DLLVM_ENABLE_FFI=ON \
-DLLVM_ENABLE_THREADS=OFF \
-DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=OFF \
-DFFI_LIBRARY_PATH=${FFI_SRCDIR}/build/Debug-iphoneos/libffi.a \
-DFFI_INCLUDE_DIR=${FFI_SRCDIR}/build_iphoneos-arm64/include \
-DLLVM_TABLEGEN=${OSX_BUILDDIR}/bin/llvm-tblgen \
-DCLANG_TABLEGEN=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-tblgen \
-DCMAKE_OSX_SYSROOT=${IOS_SDKROOT} \
-DCMAKE_C_COMPILER=${OSX_BUILDDIR}/bin/clang \
-DCMAKE_LIBRARY_PATH=${OSX_BUILDDIR}/lib/ \
-DCMAKE_INCLUDE_PATH=${OSX_BUILDDIR}/include/ \
-DCMAKE_C_FLAGS="-arch arm64 -target arm64-apple-darwin17.5.0  -D_LIBCPP_STRING_H_HAS_CONST_OVERLOADS  -I${OSX_BUILDDIR}/include/ -I${OSX_BUILDDIR}/include/c++/v1/ -I${IOS_SYSTEM} -miphoneos-version-min=11  " \
-DCMAKE_CXX_FLAGS="-arch arm64 -target arm64-apple-darwin17.5.0 -stdlib=libc++ -D_LIBCPP_STRING_H_HAS_CONST_OVERLOADS -I${OSX_BUILDDIR}/include/  -I${IOS_SYSTEM} -miphoneos-version-min=11 " \
..
ninja

# Now build the static libraries for the executables:
rm -f lib/liblli.a
# Xcode gets confused if a static and a dynamic library share the same name:
rm -f lib/libclang_tool.a
rm -f lib/libopt.a
ar -r lib/liblli.a tools/lli/CMakeFiles/lli.dir/lli.cpp.o tools/lli/CMakeFiles/lli.dir/OrcLazyJIT.cpp.o 
ar -r lib/libclang_tool.a tools/clang/tools/driver/CMakeFiles/clang.dir/driver.cpp.o tools/clang/tools/driver/CMakeFiles/clang.dir/cc1_main.cpp.o tools/clang/tools/driver/CMakeFiles/clang.dir/cc1as_main.cpp.o tools/clang/tools/driver/CMakeFiles/clang.dir/cc1gen_reproducer_main.cpp.o  
ar -r lib/libopt.a  tools/opt/CMakeFiles/opt.dir/AnalysisWrappers.cpp.o tools/opt/CMakeFiles/opt.dir/BreakpointPrinter.cpp.o tools/opt/CMakeFiles/opt.dir/Debugify.cpp.o tools/opt/CMakeFiles/opt.dir/GraphPrinters.cpp.o tools/opt/CMakeFiles/opt.dir/NewPMDriver.cpp.o tools/opt/CMakeFiles/opt.dir/PassPrinters.cpp.o tools/opt/CMakeFiles/opt.dir/PrintSCC.cpp.o tools/opt/CMakeFiles/opt.dir/opt.cpp.o
