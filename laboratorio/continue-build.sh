#!/bin/bash
# Continua o build do kernel em background
cd /home/deivi/Projetos/Android16-Kernel/kernel-moonstone-devs
export ARCH=arm64
export LLVM=1
export CC=clang
export KCFLAGS="-Wno-format -Wno-format-security -Wno-unused-variable"
export KBUILD_BUILD_USER="deivison"
export KBUILD_BUILD_HOST="DeiviPC"

echo "🚀 Continuando build..." | tee -a /home/deivi/Projetos/Android16-Kernel/laboratorio/build-final.log
echo "⏰ Início: $(date)" | tee -a /home/deivi/Projetos/Android16-Kernel/laboratorio/build-final.log

make -j$(nproc) Image.gz 2>&1 | tee -a /home/deivi/Projetos/Android16-Kernel/laboratorio/build-final.log

if [ -f arch/arm64/boot/Image.gz ]; then
    echo "✅ BUILD COMPLETO!" | tee -a /home/deivi/Projetos/Android16-Kernel/laboratorio/build-final.log
    cp arch/arm64/boot/Image.gz /home/deivi/Projetos/Android16-Kernel/laboratorio/out/
    echo "📦 Kernel copiado para out/" | tee -a /home/deivi/Projetos/Android16-Kernel/laboratorio/build-final.log
else
    echo "❌ Build falhou" | tee -a /home/deivi/Projetos/Android16-Kernel/laboratorio/build-final.log
fi

echo "⏰ Fim: $(date)" | tee -a /home/deivi/Projetos/Android16-Kernel/laboratorio/build-final.log
