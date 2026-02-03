#!/bin/bash
# Build script for Kernel 5.4.302 with KernelSU v0.9.5

set -e

cd /home/deivi/Projetos/android16-kernel/kernel-moonstone-devs

# Export build environment
export NDK_PATH=$HOME/Downloads/android-ndk-r26d
export CLANG_BIN=$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin
export ARCH=arm64
export SUBARCH=arm64
export CC=$CLANG_BIN/clang
export CXX=$CLANG_BIN/clang++
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export LLVM=1
export PATH=$CLANG_BIN:$PATH
export KCFLAGS="-Wno-error -O2 -pipe"
export KAFLAGS="-Wno-error"

echo "=== Kernel Build with KernelSU v0.9.5 ==="
echo "Cleaning..."
make clean 2>/dev/null || true

echo "Setting up KernelSU symlink..."
rm -f drivers/kernelsu
ln -sf ../KernelSU/kernel drivers/kernelsu

echo "Configuring..."
make ARCH=arm64 moonstone_defconfig

echo "Building kernel..."
time make ARCH=arm64 -j$(nproc) Image.gz 2>&1 | tee /tmp/build-kernelsu-final.log

echo "Build complete!"
ls -lh arch/arm64/boot/Image.gz
