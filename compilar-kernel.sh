#!/bin/bash
# Quick build script for POCO X5 5G kernel
# Based on successful build v12

set -e

cd ~/Projetos/android16-kernel/kernel-source

# Setup environment
export NDK_PATH=~/Downloads/android-ndk-r26d
export NDK_BIN=$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin
export PATH=$NDK_BIN:$PATH
export ARCH=arm64
export SUBARCH=arm64
export CC=$NDK_BIN/clang
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=aarch64-linux-gnu-
export KCFLAGS="-O2 -pipe"

# Build
echo "Starting kernel build..."
time make WERROR=0 -j$(nproc) Image.gz 2>&1 | tee ~/Projetos/android16-kernel/logs/build-$(date +%Y%m%d-%H%M%S).log

# Verify
if [ -f arch/arm64/boot/Image.gz ]; then
    echo ""
    echo "✅ BUILD SUCCESS!"
    echo ""
    ls -lh arch/arm64/boot/Image.gz
    file arch/arm64/boot/Image.gz
    md5sum arch/arm64/boot/Image.gz
    echo ""
    echo "Kernel ready at: arch/arm64/boot/Image.gz"
else
    echo ""
    echo "❌ BUILD FAILED!"
    echo "Check logs in ~/Projetos/android16-kernel/logs/"
    exit 1
fi
